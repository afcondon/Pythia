{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

-- |
-- Build orchestration for Python backend
--
module Language.PureScript.Python.Make
  ( compile
  , CompileOptions(..)
  ) where

import Prelude

import Control.Monad (forM_, when)
import Control.Monad.Except (runExceptT, throwError)
import Control.Monad.IO.Class (liftIO)
import Data.List (partition)
import Data.Aeson (decodeFileStrict)
import Data.Aeson.Types (parseMaybe)
import qualified Data.Set as Set
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath ((</>), takeDirectory)
import System.FilePath.Glob (glob)

import qualified Language.PureScript as P
import qualified Language.PureScript.CoreFn as CoreFn
import qualified Language.PureScript.CoreFn.FromJSON as CoreFn
import Language.PureScript.PSString (PSString, decodeString)

import Language.PureScript.Python.CodeGen.Common (pyModuleNameBase, identToPyName)

-- Note: Arity-based uncurrying requires tracking arities across module boundaries.
-- The recommended approach is to integrate with purescript-backend-optimizer,
-- which provides this infrastructure. See docs/ROADMAP.md for details.

data CompileOptions = CompileOptions
  { inputDir :: FilePath    -- ^ Directory containing corefn.json files (usually "output")
  , outputDir :: FilePath   -- ^ Directory for Python output (usually "output-py")
  }

-- | Compile all modules in the input directory
compile :: CompileOptions -> IO ()
compile opts = do
  let coreFnGlob = inputDir opts </> "*" </> "corefn.json"
  corefnFiles <- glob coreFnGlob

  when (null corefnFiles) $ do
    putStrLn "No corefn.json files found. Run 'spago build' first."
    return ()

  putStrLn $ "Found " ++ show (length corefnFiles) ++ " modules to compile"

  -- Create output directory
  createDirectoryIfMissing True (outputDir opts)

  -- Process each module
  forM_ corefnFiles $ \corefnFile -> do
    result <- compileModule opts corefnFile
    case result of
      Left err -> putStrLn $ "Error: " ++ err
      Right moduleName -> putStrLn $ "Compiled: " ++ T.unpack moduleName

  -- Generate __init__.py files for packages
  generateInitFiles (outputDir opts)

  -- Generate runtime support
  generateRuntime (outputDir opts)

  putStrLn "Done!"

-- | Compile a single module
compileModule :: CompileOptions -> FilePath -> IO (Either String T.Text)
compileModule opts corefnFile = runExceptT $ do
  -- Parse CoreFn JSON
  mModule <- liftIO $ decodeFileStrict corefnFile
  case mModule of
    Nothing -> throwError $ "Failed to parse: " ++ corefnFile
    Just jsonValue -> do
      -- Use PureScript's CoreFn.FromJSON to parse
      case parseMaybe CoreFn.moduleFromJSON jsonValue of
        Nothing -> throwError $ "CoreFn parse error in: " ++ corefnFile
        Just (_version, cfModule) -> do
          -- Generate Python using simple direct translation
          let moduleName = CoreFn.moduleName cfModule
              pyModName = pyModuleNameBase moduleName
              outFile = outputDir opts </> T.unpack pyModName ++ ".py"

          -- Get imports (excluding Prim.* modules which have no runtime representation)
          let isPrimModule (P.ModuleName mn) = T.isPrefixOf "Prim" mn
              imports = filter (not . isPrimModule) $
                        map snd (CoreFn.moduleImports cfModule)

          -- Get foreign imports for this module
          let foreigns = CoreFn.moduleForeign cfModule

          -- Generate Python code directly (simplified approach)
          let pyCode = generateModulePy cfModule

          -- Add module header with imports (including foreign module if needed)
          let header = generateHeader moduleName imports (not $ null foreigns)
              fullCode = header <> pyCode

          -- Write output file
          liftIO $ do
            createDirectoryIfMissing True (takeDirectory outFile)
            TIO.writeFile outFile fullCode

          return pyModName

-- | Collect all local variable references from an expression
collectLocalRefs :: P.ModuleName -> CoreFn.Expr CoreFn.Ann -> Set.Set T.Text
collectLocalRefs currentMod = go
  where
    go :: CoreFn.Expr CoreFn.Ann -> Set.Set T.Text
    go = \case
      CoreFn.Literal _ lit -> goLit lit
      CoreFn.Var _ (P.Qualified qb ident) ->
        case qb of
          P.ByModuleName mn | mn == currentMod -> Set.singleton (identToPyName ident)
          P.BySourcePos _ -> Set.singleton (identToPyName ident)
          _ -> Set.empty
      CoreFn.Abs _ _ body -> go body
      CoreFn.App _ fn arg -> go fn <> go arg
      CoreFn.Let _ binds body -> foldMap goBind binds <> go body
      CoreFn.Case _ exprs alts -> foldMap go exprs <> foldMap goAlt alts
      CoreFn.Accessor _ _ expr -> go expr
      CoreFn.ObjectUpdate _ expr _ updates -> go expr <> foldMap (go . snd) updates
      CoreFn.Constructor {} -> Set.empty

    goLit :: CoreFn.Literal (CoreFn.Expr CoreFn.Ann) -> Set.Set T.Text
    goLit = \case
      CoreFn.ArrayLiteral exprs -> foldMap go exprs
      CoreFn.ObjectLiteral fields -> foldMap (go . snd) fields
      _ -> Set.empty

    goBind :: CoreFn.Bind CoreFn.Ann -> Set.Set T.Text
    goBind (CoreFn.NonRec _ _ expr) = go expr
    goBind (CoreFn.Rec bindings) = foldMap (go . snd) bindings

    goAlt :: CoreFn.CaseAlternative CoreFn.Ann -> Set.Set T.Text
    goAlt (CoreFn.CaseAlternative _ result) =
      case result of
        Left guards -> foldMap (\(g, b) -> go g <> go b) guards
        Right body -> go body

-- | Generate Python code for a module (simplified direct translation)
generateModulePy :: CoreFn.Module CoreFn.Ann -> T.Text
generateModulePy cfModule = T.unlines $ map (generateBinding []) (CoreFn.moduleDecls cfModule)
  where
    currentModule :: P.ModuleName
    currentModule = CoreFn.moduleName cfModule

    -- | Generate a binding, tracking names in current Rec group (if any)
    generateBinding :: [T.Text] -> CoreFn.Bind CoreFn.Ann -> T.Text
    generateBinding _ (CoreFn.NonRec _ ident expr) =
      identName ident <> " = " <> generateExpr [] expr
    generateBinding _ (CoreFn.Rec bindings) =
      -- Smart Rec detection: only thunk bindings that actually reference
      -- other bindings in the group
      let modName = case currentModule of
            P.ModuleName mn -> mn
          allNames = Set.fromList [identName ident | ((_, ident), _) <- bindings]
          -- For each binding, check if it references any name in the group
          needsThunk ((_, _ident), expr) =
            let refs = collectLocalRefs currentModule expr
                -- A binding needs a thunk if it references any binding in the group
            in not $ Set.null $ Set.intersection refs allNames
          -- Partition into truly recursive and non-recursive
          (recursive, nonRecursive) = partition needsThunk bindings
          recNames = [identName ident | ((_, ident), _) <- recursive]
          -- Generate non-recursive bindings first (simple assignment)
          nonRecDefs = [ identName ident <> " = " <> generateExpr [] expr
                       | ((_, ident), expr) <- nonRecursive
                       ]
          -- Generate lazy thunks only for truly recursive bindings
          lazyDefs = [ "_lazy_" <> identName ident <> " = _runtime_lazy(\"" <> identName ident <> "\", \"" <> modName <> "\", lambda: " <> generateExpr recNames expr <> ")"
                     | ((_, ident), expr) <- recursive
                     ]
          -- Force evaluation of recursive bindings
          valueDefs = [ identName ident <> " = _lazy_" <> identName ident <> "()"
                      | ((_, ident), _) <- recursive
                      ]
      in T.unlines (nonRecDefs ++ lazyDefs ++ valueDefs)

    identName :: P.Ident -> T.Text
    identName = identToPyName

    -- | Generate expression, tracking names in current Rec group for thunk calls
    generateExpr :: [T.Text] -> CoreFn.Expr CoreFn.Ann -> T.Text
    generateExpr recNames = \case
      CoreFn.Literal _ lit -> generateLiteral recNames lit
      CoreFn.Var _ qi -> generateQualifiedIdent recNames qi

      -- Keep lambda definitions curried for cross-module compatibility
      -- (We only optimize fully-saturated calls within this module)
      CoreFn.Abs _ arg body ->
        "(lambda " <> identName arg <> ": " <> generateExpr recNames body <> ")"

      -- Application: generate curried form
      -- (Uncurrying requires global arity tracking - future enhancement)
      CoreFn.App _ fn arg ->
        "(" <> generateExpr recNames fn <> ")(" <> generateExpr recNames arg <> ")"

      CoreFn.Let _ binds body ->
        "(lambda: (" <> T.intercalate ", " (map (generateLetBind recNames) binds) <> ", " <> generateExpr recNames body <> ")[-1])()"
      CoreFn.Case _ exprs alts ->
        -- Generate proper pattern matching
        case exprs of
          -- Single scrutinee - most common case
          [scrutinee] ->
            let scrutineeCode = generateExpr recNames scrutinee
            in "(lambda __v__: " <> generateAlternatives recNames alts <> ")(" <> scrutineeCode <> ")"
          -- Multiple scrutinees - wrap in tuple
          _ ->
            let scrutineeCode = "(" <> T.intercalate ", " (map (generateExpr recNames) exprs) <> ")"
            in "(lambda __v__: " <> generateAlternatives recNames alts <> ")(" <> scrutineeCode <> ")"
      CoreFn.Accessor _ field expr ->
        generateExpr recNames expr <> "[\"" <> psToText field <> "\"]"
      CoreFn.ObjectUpdate _ expr _ updates ->
        "{**" <> generateExpr recNames expr <> ", " <>
        T.intercalate ", " ["\"" <> psToText k <> "\": " <> generateExpr recNames v | (k, v) <- updates] <> "}"
      CoreFn.Constructor _ _ (P.ProperName ctor) fields ->
        if null fields
          then "(\"" <> ctor <> "\",)"
          else "(lambda " <> T.intercalate ": lambda " (map identName fields) <>
               ": (\"" <> ctor <> "\", " <> T.intercalate ", " (map identName fields) <> "))"

    generateLetBind :: [T.Text] -> CoreFn.Bind CoreFn.Ann -> T.Text
    generateLetBind recNames (CoreFn.NonRec _ ident expr) =
      "(" <> identName ident <> " := " <> generateExpr recNames expr <> ")"
    generateLetBind recNames (CoreFn.Rec bindings) =
      -- For recursive bindings, we assign each in sequence (works for simple cases)
      T.intercalate ", " [
        "(" <> identName ident <> " := " <> generateExpr recNames expr <> ")"
        | ((_, ident), expr) <- bindings
      ]

    -- | Generate pattern matching alternatives using nested conditionals
    -- The scrutinee is bound to __v__ in the enclosing lambda
    generateAlternatives :: [T.Text] -> [CoreFn.CaseAlternative CoreFn.Ann] -> T.Text
    generateAlternatives recNames alts =
      foldr (generateAlt recNames) "None" alts

    -- | Generate a single alternative with pattern check and bindings
    -- Returns: "body if pattern_matches else rest"
    generateAlt :: [T.Text] -> CoreFn.CaseAlternative CoreFn.Ann -> T.Text -> T.Text
    generateAlt recNames (CoreFn.CaseAlternative binders result) rest =
      case result of
        Left guards ->
          -- Guarded case: list of (guard_expr, body_expr) pairs
          -- Generate: body1 if guard1 else (body2 if guard2 else ... rest)
          let generateGuards [] = rest
              generateGuards ((guard, body):gs) =
                let guardCode = generateExpr recNames guard
                    bodyCode = generateExpr recNames body
                    restCode = generateGuards gs
                in "(" <> bodyCode <> " if " <> guardCode <> " else " <> restCode <> ")"
              -- First, bind pattern variables, then evaluate guards
              patResults = case binders of
                [binder] -> [generatePattern recNames "__v__" binder]
                _ -> zipWith (\i b -> generatePattern recNames ("__v__[" <> T.pack (show i) <> "]") b) [(0::Int)..] binders
              -- Extract conditions (for constructor tag checks) and bindings separately
              conds = filter (/= "True") $ map fst patResults
              allBindings = concatMap snd patResults
              combinedCond = if null conds then "True" else T.intercalate " and " conds
              guardedCode = generateGuards guards
              -- Wrap with bindings if needed
              withBindings = if null allBindings
                             then guardedCode
                             else "(lambda: (" <> T.intercalate ", " allBindings <> ", " <> guardedCode <> ")[-1])()"
          -- Wrap with constructor tag check if needed
          in if combinedCond == "True"
             then withBindings
             else "((" <> withBindings <> ") if " <> combinedCond <> " else " <> rest <> ")"
        Right body ->
          case binders of
            -- Single binder patterns
            [binder] ->
              let (cond, bindings) = generatePattern recNames "__v__" binder
              in case (cond, bindings) of
                -- VarBinder or NullBinder: always matches, just bind and continue
                ("True", []) -> generateExpr recNames body
                ("True", _) ->
                  "(lambda: (" <> T.intercalate ", " bindings <> ", " <> generateExpr recNames body <> ")[-1])()"
                -- Pattern with condition: if/else
                (_, []) ->
                  "(" <> generateExpr recNames body <> " if " <> cond <> " else " <> rest <> ")"
                (_, _) ->
                  "(((lambda: (" <> T.intercalate ", " bindings <> ", " <> generateExpr recNames body <> ")[-1])()) if " <> cond <> " else " <> rest <> ")"
            -- Multiple binder patterns (tuple destructuring)
            _ ->
              let patResults = zipWith (\i b -> generatePattern recNames ("__v__[" <> T.pack (show i) <> "]") b) [(0::Int)..] binders
                  conds = filter (/= "True") $ map fst patResults
                  allBindings = concatMap snd patResults
                  combinedCond = if null conds then "True" else T.intercalate " and " conds
              in case (combinedCond, allBindings) of
                ("True", []) -> generateExpr recNames body
                ("True", _) ->
                  "(lambda: (" <> T.intercalate ", " allBindings <> ", " <> generateExpr recNames body <> ")[-1])()"
                (_, []) ->
                  "(" <> generateExpr recNames body <> " if " <> combinedCond <> " else " <> rest <> ")"
                (_, _) ->
                  "(((lambda: (" <> T.intercalate ", " allBindings <> ", " <> generateExpr recNames body <> ")[-1])()) if " <> combinedCond <> " else " <> rest <> ")"

    -- | Generate pattern match condition and bindings
    -- Returns (condition_expr, [binding_exprs])
    generatePattern :: [T.Text] -> T.Text -> CoreFn.Binder CoreFn.Ann -> (T.Text, [T.Text])
    generatePattern _ scrutinee (CoreFn.VarBinder _ ident) =
      -- Variable binder: always matches, binds the value
      ("True", ["(" <> identName ident <> " := " <> scrutinee <> ")"])
    generatePattern _ _ (CoreFn.NullBinder _) =
      -- Null binder: always matches, binds nothing
      ("True", [])
    generatePattern recNames scrutinee (CoreFn.LiteralBinder _ lit) =
      -- Literal binder: compare with literal
      case lit of
        CoreFn.NumericLiteral (Left n) ->
          (scrutinee <> " == " <> T.pack (show n), [])
        CoreFn.NumericLiteral (Right n) ->
          (scrutinee <> " == " <> T.pack (show n), [])
        CoreFn.StringLiteral s ->
          case decodeString s of
            Just str -> (scrutinee <> " == \"" <> escapeString str <> "\"", [])
            Nothing -> ("False", [])
        CoreFn.CharLiteral c ->
          (scrutinee <> " == \"" <> T.singleton c <> "\"", [])
        CoreFn.BooleanLiteral True ->
          (scrutinee <> " == True", [])
        CoreFn.BooleanLiteral False ->
          (scrutinee <> " == False", [])
        CoreFn.ArrayLiteral binders ->
          -- Array pattern matching: check length and match each element
          let lenCheck = scrutinee <> " is not None and len(" <> scrutinee <> ") == " <> T.pack (show (length binders))
              elemPatterns = zipWith (\i b -> generatePattern recNames (scrutinee <> "[" <> T.pack (show i) <> "]") b) [(0::Int)..] binders
              elemConds = filter (/= "True") $ map fst elemPatterns
              elemBindings = concatMap snd elemPatterns
              combinedCond = if null elemConds
                             then lenCheck
                             else lenCheck <> " and " <> T.intercalate " and " elemConds
          in (combinedCond, elemBindings)
        CoreFn.ObjectLiteral fields ->
          -- Object/record pattern matching: extract each field and match
          let fieldPatterns = map (\(fieldName, binder) ->
                let fieldStr = case decodeString fieldName of
                      Just s -> s
                      Nothing -> "unknown"
                    fieldAccess = scrutinee <> "[\"" <> fieldStr <> "\"]"
                in generatePattern recNames fieldAccess binder) fields
              fieldConds = filter (/= "True") $ map fst fieldPatterns
              fieldBindings = concatMap snd fieldPatterns
              combinedCond = if null fieldConds then "True" else T.intercalate " and " fieldConds
          in (combinedCond, fieldBindings)
    generatePattern recNames scrutinee (CoreFn.ConstructorBinder ann _tyName (P.Qualified _ (P.ProperName ctorName)) subBinders) =
      -- Constructor binder: check tag and recursively match fields
      case ann of
        (_, _, Just CoreFn.IsNewtype) ->
          -- Newtype: no tag check, just pass through to inner binder
          case subBinders of
            [inner] -> generatePattern recNames scrutinee inner
            _ -> ("True", [])  -- shouldn't happen for newtypes
        _ ->
          -- Regular constructor: check tag, then match fields
          let tagCheck = scrutinee <> "[0] == \"" <> ctorName <> "\""
              fieldPatterns = zipWith (\i b -> generatePattern recNames (scrutinee <> "[" <> T.pack (show (i+1)) <> "]") b) [(0::Int)..] subBinders
              fieldConds = filter (/= "True") $ map fst fieldPatterns
              fieldBindings = concatMap snd fieldPatterns
              combinedCond = if null fieldConds
                             then tagCheck
                             else tagCheck <> " and " <> T.intercalate " and " fieldConds
          in (combinedCond, fieldBindings)
    generatePattern recNames scrutinee (CoreFn.NamedBinder _ ident inner) =
      -- Named binder: bind and also match inner pattern
      let (innerCond, innerBindings) = generatePattern recNames scrutinee inner
          binding = "(" <> identName ident <> " := " <> scrutinee <> ")"
      in (innerCond, binding : innerBindings)

    generateLiteral :: [T.Text] -> CoreFn.Literal (CoreFn.Expr CoreFn.Ann) -> T.Text
    generateLiteral recNames = \case
      CoreFn.NumericLiteral (Left n) -> T.pack (show n)
      CoreFn.NumericLiteral (Right n) -> T.pack (show n)
      CoreFn.StringLiteral s ->
        case decodeString s of
          Just str -> "\"" <> escapeString str <> "\""
          Nothing -> "\"<invalid string>\""
      CoreFn.CharLiteral c -> "\"" <> T.singleton c <> "\""
      CoreFn.BooleanLiteral True -> "True"
      CoreFn.BooleanLiteral False -> "False"
      CoreFn.ArrayLiteral exprs -> "[" <> T.intercalate ", " (map (generateExpr recNames) exprs) <> "]"
      CoreFn.ObjectLiteral fields ->
        "{" <> T.intercalate ", " ["\"" <> psToText k <> "\": " <> generateExpr recNames v | (k, v) <- fields] <> "}"

    psToText :: PSString -> T.Text
    psToText s = case decodeString s of
      Just str -> str
      Nothing -> "<invalid>"

    generateQualifiedIdent :: [T.Text] -> P.Qualified P.Ident -> T.Text
    generateQualifiedIdent recNames (P.Qualified qb ident) =
      let name = identName ident
          -- If this name is in the current Rec group, reference the _lazy_ thunk and call it
          -- This is needed because Python doesn't hoist variable definitions like JavaScript
          maybeCallLazyThunk n = if n `elem` recNames then "_lazy_" <> n <> "()" else n
      in case qb of
        P.ByModuleName (P.ModuleName "Effect.Console")
          | P.runIdent ident == "log" -> "effect_console_log"
        P.ByModuleName (P.ModuleName "Prim")
          | P.runIdent ident == "undefined" -> "None"
        P.ByModuleName mn
          | mn == currentModule -> maybeCallLazyThunk name  -- Same module: unqualified, maybe thunk
          | otherwise -> pyModuleNameBase mn <> "." <> identName ident
        P.BySourcePos _ -> maybeCallLazyThunk name  -- Local reference, maybe thunk

    escapeString :: T.Text -> T.Text
    escapeString = T.concatMap escapeChar
      where
        escapeChar '\\' = "\\\\"
        escapeChar '"' = "\\\""
        escapeChar '\n' = "\\n"
        escapeChar '\r' = "\\r"
        escapeChar '\t' = "\\t"
        escapeChar c = T.singleton c

-- | Generate module header with imports
generateHeader :: P.ModuleName -> [P.ModuleName] -> Bool -> T.Text
generateHeader mn@(P.ModuleName name) imports hasForeign = T.unlines $
  [ "# Generated by purepy from PureScript module: " <> name
  , "# Do not edit this file directly"
  , ""
  , "from purepy_runtime import *"
  ] ++
  -- Import foreign module if this module has foreign imports
  (if hasForeign
   then ["from " <> pyModuleNameBase mn <> "_foreign import *"]
   else []) ++
  -- Generate import for each dependency (excluding self-import)
  [ "import " <> pyModuleNameBase depMn
  | depMn <- imports
  , depMn /= mn  -- Don't import self
  ] ++
  [ "" ]

-- | Generate __init__.py files
generateInitFiles :: FilePath -> IO ()
generateInitFiles dir = do
  let initFile = dir </> "__init__.py"
  exists <- doesFileExist initFile
  when (not exists) $ do
    TIO.writeFile initFile "# PureScript Python output\n"

-- | Generate runtime support module
generateRuntime :: FilePath -> IO ()
generateRuntime dir = do
  let runtimeFile = dir </> "purepy_runtime.py"
  TIO.writeFile runtimeFile runtimeCode
  -- Also generate FFI files for core modules
  generateFFIFiles dir

-- | Generate Python FFI files for core modules
generateFFIFiles :: FilePath -> IO ()
generateFFIFiles dir = do
  -- Data.Unit
  TIO.writeFile (dir </> "data_unit_foreign.py") $ T.unlines
    [ "# FFI for Data.Unit"
    , "unit = None"
    ]
  -- Data.HeytingAlgebra
  TIO.writeFile (dir </> "data_heyting_algebra_foreign.py") $ T.unlines
    [ "# FFI for Data.HeytingAlgebra"
    , "def boolConj(b1):"
    , "    return lambda b2: b1 and b2"
    , ""
    , "def boolDisj(b1):"
    , "    return lambda b2: b1 or b2"
    , ""
    , "def boolNot(b):"
    , "    return not b"
    ]
  -- Effect
  TIO.writeFile (dir </> "effect_foreign.py") $ T.unlines
    [ "# FFI for Effect"
    , "def pureE(a):"
    , "    return lambda: a"
    , ""
    , "def bindE(a):"
    , "    return lambda f: lambda: f(a())()"
    , ""
    , "def untilE(f):"
    , "    def effect():"
    , "        while not f():"
    , "            pass"
    , "    return effect"
    , ""
    , "def whileE(f):"
    , "    def go(a):"
    , "        def effect():"
    , "            while f():"
    , "                a()"
    , "        return effect"
    , "    return go"
    , ""
    , "def forE(lo):"
    , "    def step1(hi):"
    , "        def step2(f):"
    , "            def effect():"
    , "                for i in range(lo, hi):"
    , "                    f(i)()"
    , "            return effect"
    , "        return step2"
    , "    return step1"
    , ""
    , "def foreachE(xs):"
    , "    def step(f):"
    , "        def effect():"
    , "            for x in xs:"
    , "                f(x)()"
    , "        return effect"
    , "    return step"
    ]
  -- Effect.Unsafe
  TIO.writeFile (dir </> "effect_unsafe_foreign.py") $ T.unlines
    [ "# FFI for Effect.Unsafe"
    , "def unsafePerformEffect(f):"
    , "    return f()"
    ]
  -- Control.Bind
  TIO.writeFile (dir </> "control_bind_foreign.py") $ T.unlines
    [ "# FFI for Control.Bind"
    , "def arrayBind(arr):"
    , "    def step(f):"
    , "        result = []"
    , "        for x in arr:"
    , "            result.extend(f(x))"
    , "        return result"
    , "    return step"
    ]
  -- Control.Apply
  TIO.writeFile (dir </> "control_apply_foreign.py") $ T.unlines
    [ "# FFI for Control.Apply"
    , "def arrayApply(fs):"
    , "    def step(xs):"
    , "        result = []"
    , "        for f in fs:"
    , "            for x in xs:"
    , "                result.append(f(x))"
    , "        return result"
    , "    return step"
    ]
  -- Data.Eq
  TIO.writeFile (dir </> "data_eq_foreign.py") $ T.unlines
    [ "# FFI for Data.Eq"
    , "def eqBooleanImpl(r1):"
    , "    return lambda r2: r1 == r2"
    , ""
    , "def eqIntImpl(r1):"
    , "    return lambda r2: r1 == r2"
    , ""
    , "def eqNumberImpl(r1):"
    , "    return lambda r2: r1 == r2"
    , ""
    , "def eqCharImpl(r1):"
    , "    return lambda r2: r1 == r2"
    , ""
    , "def eqStringImpl(r1):"
    , "    return lambda r2: r1 == r2"
    , ""
    , "def eqArrayImpl(f):"
    , "    def step(xs):"
    , "        def step2(ys):"
    , "            if len(xs) != len(ys):"
    , "                return False"
    , "            for x, y in zip(xs, ys):"
    , "                if not f(x)(y):"
    , "                    return False"
    , "            return True"
    , "        return step2"
    , "    return step"
    ]
  -- Data.Ord
  TIO.writeFile (dir </> "data_ord_foreign.py") $ T.unlines
    [ "# FFI for Data.Ord"
    , "def ordBooleanImpl(lt):"
    , "    def step_eq(eq):"
    , "        def step_gt(gt):"
    , "            def cmp(x):"
    , "                def cmp2(y):"
    , "                    if x < y: return lt"
    , "                    elif x == y: return eq"
    , "                    else: return gt"
    , "                return cmp2"
    , "            return cmp"
    , "        return step_gt"
    , "    return step_eq"
    , ""
    , "def ordIntImpl(lt):"
    , "    return ordBooleanImpl(lt)"
    , ""
    , "def ordNumberImpl(lt):"
    , "    return ordBooleanImpl(lt)"
    , ""
    , "def ordStringImpl(lt):"
    , "    return ordBooleanImpl(lt)"
    , ""
    , "def ordCharImpl(lt):"
    , "    return ordBooleanImpl(lt)"
    ]
  -- Data.Show
  TIO.writeFile (dir </> "data_show_foreign.py") $ T.unlines
    [ "# FFI for Data.Show"
    , "def showIntImpl(n):"
    , "    return str(n)"
    , ""
    , "def showNumberImpl(n):"
    , "    return str(n)"
    , ""
    , "def showCharImpl(c):"
    , "    return repr(c)"
    , ""
    , "def showStringImpl(s):"
    , "    return repr(s)"
    , ""
    , "def showArrayImpl(f):"
    , "    return lambda xs: '[' + ', '.join(f(x) for x in xs) + ']'"
    ]
  -- Data.Semiring
  TIO.writeFile (dir </> "data_semiring_foreign.py") $ T.unlines
    [ "# FFI for Data.Semiring"
    , "def intAdd(x):"
    , "    return lambda y: x + y"
    , ""
    , "def intMul(x):"
    , "    return lambda y: x * y"
    , ""
    , "def numAdd(x):"
    , "    return lambda y: x + y"
    , ""
    , "def numMul(x):"
    , "    return lambda y: x * y"
    ]
  -- Data.Ring
  TIO.writeFile (dir </> "data_ring_foreign.py") $ T.unlines
    [ "# FFI for Data.Ring"
    , "def intSub(x):"
    , "    return lambda y: x - y"
    , ""
    , "def numSub(x):"
    , "    return lambda y: x - y"
    ]
  -- Data.EuclideanRing
  TIO.writeFile (dir </> "data_euclidean_ring_foreign.py") $ T.unlines
    [ "# FFI for Data.EuclideanRing"
    , "def intDiv(x):"
    , "    return lambda y: x // y if y != 0 else 0"
    , ""
    , "def intMod(x):"
    , "    return lambda y: x % y if y != 0 else 0"
    , ""
    , "def intDegree(x):"
    , "    return abs(x)"
    , ""
    , "def numDiv(x):"
    , "    return lambda y: x / y if y != 0 else 0.0"
    ]
  -- Data.Bounded
  TIO.writeFile (dir </> "data_bounded_foreign.py") $ T.unlines
    [ "# FFI for Data.Bounded"
    , "topInt = 2147483647"
    , "bottomInt = -2147483648"
    , "topChar = chr(65535)"
    , "bottomChar = chr(0)"
    , "topNumber = float('inf')"
    , "bottomNumber = float('-inf')"
    ]
  -- Data.Semigroup
  TIO.writeFile (dir </> "data_semigroup_foreign.py") $ T.unlines
    [ "# FFI for Data.Semigroup"
    , "def concatString(s1):"
    , "    return lambda s2: s1 + s2"
    , ""
    , "def concatArray(xs):"
    , "    return lambda ys: xs + ys"
    ]
  -- Data.Functor
  TIO.writeFile (dir </> "data_functor_foreign.py") $ T.unlines
    [ "# FFI for Data.Functor"
    , "def arrayMap(f):"
    , "    return lambda xs: [f(x) for x in xs]"
    ]
  -- Record.Unsafe
  TIO.writeFile (dir </> "record_unsafe_foreign.py") $ T.unlines
    [ "# FFI for Record.Unsafe"
    , "def unsafeGet(key):"
    , "    return lambda rec: rec[key]"
    , ""
    , "def unsafeSet(key):"
    , "    def step(val):"
    , "        def step2(rec):"
    , "            result = dict(rec)"
    , "            result[key] = val"
    , "            return result"
    , "        return step2"
    , "    return step"
    , ""
    , "def unsafeDelete(key):"
    , "    def step(rec):"
    , "        result = dict(rec)"
    , "        del result[key]"
    , "        return result"
    , "    return step"
    ]
  -- Data.Symbol
  TIO.writeFile (dir </> "data_symbol_foreign.py") $ T.unlines
    [ "# FFI for Data.Symbol"
    , "# Note: reflectSymbol is handled specially at compile time"
    ]
  -- Data.Reflectable
  TIO.writeFile (dir </> "data_reflectable_foreign.py") $ T.unlines
    [ "# FFI for Data.Reflectable"
    , "# Note: reflectType is handled specially at compile time"
    ]
  -- Data.Show.Generic
  TIO.writeFile (dir </> "data_show_generic_foreign.py") $ T.unlines
    [ "# FFI for Data.Show.Generic"
    , "def intercalate(sep):"
    , "    return lambda xs: sep.join(xs)"
    ]
  -- Effect.Console (move from runtime)
  TIO.writeFile (dir </> "effect_console_foreign.py") $ T.unlines
    [ "# FFI for Effect.Console"
    , "def log(msg):"
    , "    def effect():"
    , "        print(msg)"
    , "    return effect"
    , ""
    , "def warn(msg):"
    , "    def effect():"
    , "        import sys"
    , "        print(msg, file=sys.stderr)"
    , "    return effect"
    , ""
    , "def error(msg):"
    , "    def effect():"
    , "        import sys"
    , "        print(msg, file=sys.stderr)"
    , "    return effect"
    , ""
    , "def info(msg):"
    , "    def effect():"
    , "        print(msg)"
    , "    return effect"
    , ""
    , "def debug(msg):"
    , "    def effect():"
    , "        print(msg)"
    , "    return effect"
    , ""
    , "def time(label):"
    , "    def effect():"
    , "        pass  # TODO: implement timing"
    , "    return effect"
    , ""
    , "def timeLog(label):"
    , "    def effect():"
    , "        pass  # TODO: implement timing"
    , "    return effect"
    , ""
    , "def timeEnd(label):"
    , "    def effect():"
    , "        pass  # TODO: implement timing"
    , "    return effect"
    , ""
    , "def clear():"
    , "    pass  # TODO: implement clear"
    , ""
    , "def group(label):"
    , "    def effect():"
    , "        pass  # TODO: implement grouping"
    , "    return effect"
    , ""
    , "def groupCollapsed(label):"
    , "    def effect():"
    , "        pass"
    , "    return effect"
    , ""
    , "def groupEnd():"
    , "    pass"
    ]
  -- Effect.Uncurried
  TIO.writeFile (dir </> "effect_uncurried_foreign.py") $ T.unlines
    [ "# FFI for Effect.Uncurried"
    , "def mkEffectFn1(f):"
    , "    return lambda a: f(a)()"
    , ""
    , "def mkEffectFn2(f):"
    , "    return lambda a, b: f(a)(b)()"
    , ""
    , "def mkEffectFn3(f):"
    , "    return lambda a, b, c: f(a)(b)(c)()"
    , ""
    , "def runEffectFn1(f):"
    , "    return lambda a: lambda: f(a)"
    , ""
    , "def runEffectFn2(f):"
    , "    return lambda a: lambda b: lambda: f(a, b)"
    , ""
    , "def runEffectFn3(f):"
    , "    return lambda a: lambda b: lambda c: lambda: f(a, b, c)"
    ]
  -- Data.Array
  TIO.writeFile (dir </> "data_array_foreign.py") $ T.unlines
    [ "# FFI for Data.Array"
    , "def range_(start):"
    , "    return lambda end: list(range(start, end))"
    , ""
    , "def length(arr):"
    , "    return len(arr)"
    , ""
    , "def cons(x):"
    , "    return lambda xs: [x] + xs"
    , ""
    , "def snoc(xs):"
    , "    return lambda x: xs + [x]"
    , ""
    , "def uncons(empty):"
    , "    def step(next_):"
    , "        def step2(xs):"
    , "            if len(xs) == 0:"
    , "                return empty(None)"
    , "            return next_({'head': xs[0], 'tail': xs[1:]})"
    , "        return step2"
    , "    return step"
    , ""
    , "def indexImpl(just):"
    , "    def step(nothing):"
    , "        def step2(xs):"
    , "            def step3(i):"
    , "                if i < 0 or i >= len(xs):"
    , "                    return nothing"
    , "                return just(xs[i])"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def findIndexImpl(just):"
    , "    def step(nothing):"
    , "        def step2(f):"
    , "            def step3(xs):"
    , "                for i, x in enumerate(xs):"
    , "                    if f(x):"
    , "                        return just(i)"
    , "                return nothing"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def findLastIndexImpl(just):"
    , "    def step(nothing):"
    , "        def step2(f):"
    , "            def step3(xs):"
    , "                for i in range(len(xs) - 1, -1, -1):"
    , "                    if f(xs[i]):"
    , "                        return just(i)"
    , "                return nothing"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def _insertAt(just):"
    , "    def step(nothing):"
    , "        def step2(i):"
    , "            def step3(x):"
    , "                def step4(xs):"
    , "                    if i < 0 or i > len(xs):"
    , "                        return nothing"
    , "                    result = xs[:i] + [x] + xs[i:]"
    , "                    return just(result)"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def _deleteAt(just):"
    , "    def step(nothing):"
    , "        def step2(i):"
    , "            def step3(xs):"
    , "                if i < 0 or i >= len(xs):"
    , "                    return nothing"
    , "                result = xs[:i] + xs[i+1:]"
    , "                return just(result)"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def _updateAt(just):"
    , "    def step(nothing):"
    , "        def step2(i):"
    , "            def step3(x):"
    , "                def step4(xs):"
    , "                    if i < 0 or i >= len(xs):"
    , "                        return nothing"
    , "                    result = xs[:i] + [x] + xs[i+1:]"
    , "                    return just(result)"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def reverse(xs):"
    , "    return xs[::-1]"
    , ""
    , "def concat(xss):"
    , "    result = []"
    , "    for xs in xss:"
    , "        result.extend(xs)"
    , "    return result"
    , ""
    , "def filter_(f):"
    , "    return lambda xs: [x for x in xs if f(x)]"
    , ""
    , "def partition(f):"
    , "    def step(xs):"
    , "        yes, no = [], []"
    , "        for x in xs:"
    , "            if f(x):"
    , "                yes.append(x)"
    , "            else:"
    , "                no.append(x)"
    , "        return {'yes': yes, 'no': no}"
    , "    return step"
    , ""
    , "def sortByImpl(cmp):"
    , "    def step(xs):"
    , "        from functools import cmp_to_key"
    , "        def py_cmp(a, b):"
    , "            result = cmp(a)(b)"
    , "            if result[0] == 'LT': return -1"
    , "            if result[0] == 'GT': return 1"
    , "            return 0"
    , "        return sorted(xs, key=cmp_to_key(py_cmp))"
    , "    return step"
    , ""
    , "def slice(start):"
    , "    return lambda end: lambda xs: xs[start:end]"
    , ""
    , "def take(n):"
    , "    return lambda xs: xs[:n]"
    , ""
    , "def drop(n):"
    , "    return lambda xs: xs[n:]"
    , ""
    , "def zipWith(f):"
    , "    def step(xs):"
    , "        def step2(ys):"
    , "            return [f(x)(y) for x, y in zip(xs, ys)]"
    , "        return step2"
    , "    return step"
    , ""
    , "def unsafeIndexImpl(xs):"
    , "    return lambda i: xs[i]"
    ]
  -- Data.Array.ST
  TIO.writeFile (dir </> "data_array_s_t_foreign.py") $ T.unlines
    [ "# FFI for Data.Array.ST"
    , "def new_():"
    , "    return lambda: []"
    , ""
    , "def peekImpl(just):"
    , "    def step(nothing):"
    , "        def step2(i):"
    , "            def step3(arr):"
    , "                def effect():"
    , "                    if i < 0 or i >= len(arr):"
    , "                        return nothing"
    , "                    return just(arr[i])"
    , "                return effect"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def poke(i):"
    , "    def step(x):"
    , "        def step2(arr):"
    , "            def effect():"
    , "                if 0 <= i < len(arr):"
    , "                    arr[i] = x"
    , "                    return True"
    , "                return False"
    , "            return effect"
    , "        return step2"
    , "    return step"
    , ""
    , "def pushAll(xs):"
    , "    def step(arr):"
    , "        def effect():"
    , "            start = len(arr)"
    , "            arr.extend(xs)"
    , "            return start"
    , "        return effect"
    , "    return step"
    , ""
    , "def length_(arr):"
    , "    return lambda: len(arr)"
    , ""
    , "def freeze(arr):"
    , "    return lambda: list(arr)"
    , ""
    , "def thaw(arr):"
    , "    return lambda: list(arr)"
    , ""
    , "def unsafeFreeze(arr):"
    , "    return lambda: arr"
    , ""
    , "def unsafeThaw(arr):"
    , "    return lambda: arr"
    , ""
    , "def splice(i):"
    , "    def step(n):"
    , "        def step2(xs):"
    , "            def step3(arr):"
    , "                def effect():"
    , "                    removed = arr[i:i+n]"
    , "                    arr[i:i+n] = xs"
    , "                    return removed"
    , "                return effect"
    , "            return step3"
    , "        return step2"
    , "    return step"
    , ""
    , "def copyImpl(arr):"
    , "    return lambda: list(arr)"
    , ""
    , "def sortByImpl_(cmp):"
    , "    def step(arr):"
    , "        def effect():"
    , "            from functools import cmp_to_key"
    , "            def py_cmp(a, b):"
    , "                result = cmp(a)(b)"
    , "                if result[0] == 'LT': return -1"
    , "                if result[0] == 'GT': return 1"
    , "                return 0"
    , "            arr.sort(key=cmp_to_key(py_cmp))"
    , "            return arr"
    , "        return effect"
    , "    return step"
    , ""
    , "def toAssocArray(arr):"
    , "    return lambda: [{'value': v, 'index': i} for i, v in enumerate(arr)]"
    ]
  -- Control.Monad.ST.Internal
  TIO.writeFile (dir </> "control_monad_s_t_internal_foreign.py") $ T.unlines
    [ "# FFI for Control.Monad.ST.Internal"
    , "def map__(f):"
    , "    def step(a):"
    , "        def effect():"
    , "            return f(a())"
    , "        return effect"
    , "    return step"
    , ""
    , "def pure__(a):"
    , "    return lambda: a"
    , ""
    , "def bind__(a):"
    , "    def step(f):"
    , "        def effect():"
    , "            return f(a())()"
    , "        return effect"
    , "    return step"
    , ""
    , "def run(f):"
    , "    return f()"
    , ""
    , "def while_(cond):"
    , "    def step(body):"
    , "        def effect():"
    , "            while cond():"
    , "                body()"
    , "            return None"
    , "        return effect"
    , "    return step"
    , ""
    , "def for_(lo):"
    , "    def step(hi):"
    , "        def step2(f):"
    , "            def effect():"
    , "                for i in range(lo, hi):"
    , "                    f(i)()"
    , "                return None"
    , "            return effect"
    , "        return step2"
    , "    return step"
    , ""
    , "def foreach(xs):"
    , "    def step(f):"
    , "        def effect():"
    , "            for x in xs:"
    , "                f(x)()"
    , "            return None"
    , "        return effect"
    , "    return step"
    , ""
    , "def newSTRef(val):"
    , "    return lambda: [val]"
    , ""
    , "def readSTRef(ref):"
    , "    return lambda: ref[0]"
    , ""
    , "def modifySTRef(ref):"
    , "    def step(f):"
    , "        def effect():"
    , "            ref[0] = f(ref[0])"
    , "            return None"
    , "        return effect"
    , "    return step"
    , ""
    , "def writeSTRef(ref):"
    , "    def step(val):"
    , "        def effect():"
    , "            ref[0] = val"
    , "            return None"
    , "        return effect"
    , "    return step"
    ]
  -- Effect.Ref
  TIO.writeFile (dir </> "effect_ref_foreign.py") $ T.unlines
    [ "# FFI for Effect.Ref"
    , "def _new(val):"
    , "    return lambda: [val]"
    , ""
    , "def read(ref):"
    , "    return lambda: ref[0]"
    , ""
    , "def modifyImpl(f):"
    , "    def step(ref):"
    , "        def effect():"
    , "            result = f(ref[0])"
    , "            ref[0] = result['state']"
    , "            return result['value']"
    , "        return effect"
    , "    return step"
    , ""
    , "def write(val):"
    , "    def step(ref):"
    , "        def effect():"
    , "            ref[0] = val"
    , "            return None"
    , "        return effect"
    , "    return step"
    ]
  -- Unsafe.Coerce
  TIO.writeFile (dir </> "unsafe_coerce_foreign.py") $ T.unlines
    [ "# FFI for Unsafe.Coerce"
    , "def unsafeCoerce(x):"
    , "    return x"
    ]
  -- Partial.Unsafe
  TIO.writeFile (dir </> "partial_unsafe_foreign.py") $ T.unlines
    [ "# FFI for Partial.Unsafe"
    , "def _unsafePartial(f):"
    , "    return f()"
    ]
  -- Control.Monad.Rec.Class
  TIO.writeFile (dir </> "control_monad_rec_class_foreign.py") $ T.unlines
    [ "# FFI for Control.Monad.Rec.Class"
    , "# Loop and Done constructors"
    , "Loop = lambda a: ('Loop', a)"
    , "Done = lambda a: ('Done', a)"
    ]
  -- Data.Function.Uncurried
  TIO.writeFile (dir </> "data_function_uncurried_foreign.py") $ T.unlines
    [ "# FFI for Data.Function.Uncurried"
    , "def mkFn0(f):"
    , "    return lambda: f(None)"
    , ""
    , "def mkFn1(f):"
    , "    return f"
    , ""
    , "def mkFn2(f):"
    , "    return lambda a, b: f(a)(b)"
    , ""
    , "def mkFn3(f):"
    , "    return lambda a, b, c: f(a)(b)(c)"
    , ""
    , "def mkFn4(f):"
    , "    return lambda a, b, c, d: f(a)(b)(c)(d)"
    , ""
    , "def mkFn5(f):"
    , "    return lambda a, b, c, d, e: f(a)(b)(c)(d)(e)"
    , ""
    , "def runFn0(f):"
    , "    return f()"
    , ""
    , "def runFn1(f):"
    , "    return f"
    , ""
    , "def runFn2(f):"
    , "    return lambda a: lambda b: f(a, b)"
    , ""
    , "def runFn3(f):"
    , "    return lambda a: lambda b: lambda c: f(a, b, c)"
    , ""
    , "def runFn4(f):"
    , "    return lambda a: lambda b: lambda c: lambda d: f(a, b, c, d)"
    , ""
    , "def runFn5(f):"
    , "    return lambda a: lambda b: lambda c: lambda d: lambda e: f(a, b, c, d, e)"
    ]
  -- Data.Foldable
  TIO.writeFile (dir </> "data_foldable_foreign.py") $ T.unlines
    [ "# FFI for Data.Foldable"
    , "def foldrArray(f):"
    , "    def step(init):"
    , "        def step2(xs):"
    , "            result = init"
    , "            for x in reversed(xs):"
    , "                result = f(x)(result)"
    , "            return result"
    , "        return step2"
    , "    return step"
    , ""
    , "def foldlArray(f):"
    , "    def step(init):"
    , "        def step2(xs):"
    , "            result = init"
    , "            for x in xs:"
    , "                result = f(result)(x)"
    , "            return result"
    , "        return step2"
    , "    return step"
    ]
  -- Data.Traversable
  TIO.writeFile (dir </> "data_traversable_foreign.py") $ T.unlines
    [ "# FFI for Data.Traversable"
    , "# traverseArrayImpl is complex - simplified version"
    , "def traverseArrayImpl(apply_):"
    , "    def step(map_):"
    , "        def step2(pure_):"
    , "            def step3(f):"
    , "                def step4(xs):"
    , "                    if len(xs) == 0:"
    , "                        return pure_([])"
    , "                    result = map_(lambda a: [a])(f(xs[0]))"
    , "                    for x in xs[1:]:"
    , "                        result = apply_(map_(lambda arr: lambda a: arr + [a])(result))(f(x))"
    , "                    return result"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    ]
  -- Data.Unfoldable
  TIO.writeFile (dir </> "data_unfoldable_foreign.py") $ T.unlines
    [ "# FFI for Data.Unfoldable"
    , "def unfoldrArrayImpl(isNothing):"
    , "    def step(fromJust):"
    , "        def step2(fst_):"
    , "            def step3(snd_):"
    , "                def step4(f):"
    , "                    def step5(b):"
    , "                        result = []"
    , "                        seed = b"
    , "                        while True:"
    , "                            maybe = f(seed)"
    , "                            if isNothing(maybe):"
    , "                                break"
    , "                            pair = fromJust(maybe)"
    , "                            result.append(fst_(pair))"
    , "                            seed = snd_(pair)"
    , "                        return result"
    , "                    return step5"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    ]
  -- Data.Unfoldable1
  TIO.writeFile (dir </> "data_unfoldable1_foreign.py") $ T.unlines
    [ "# FFI for Data.Unfoldable1"
    , "def unfoldr1ArrayImpl(isNothing):"
    , "    def step(fromJust):"
    , "        def step2(fst_):"
    , "            def step3(snd_):"
    , "                def step4(f):"
    , "                    def step5(b):"
    , "                        result = []"
    , "                        seed = b"
    , "                        while True:"
    , "                            pair = f(seed)"
    , "                            result.append(fst_(pair))"
    , "                            maybe_seed = snd_(pair)"
    , "                            if isNothing(maybe_seed):"
    , "                                break"
    , "                            seed = fromJust(maybe_seed)"
    , "                        return result"
    , "                    return step5"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    ]
  -- Data.FunctorWithIndex
  TIO.writeFile (dir </> "data_functor_with_index_foreign.py") $ T.unlines
    [ "# FFI for Data.FunctorWithIndex"
    , "def mapWithIndexArray(f):"
    , "    return lambda xs: [f(i)(x) for i, x in enumerate(xs)]"
    ]
  -- Data.FoldableWithIndex
  TIO.writeFile (dir </> "data_foldable_with_index_foreign.py") $ T.unlines
    [ "# FFI for Data.FoldableWithIndex"
    , "def foldrWithIndexArray(f):"
    , "    def step(init):"
    , "        def step2(xs):"
    , "            result = init"
    , "            for i in range(len(xs) - 1, -1, -1):"
    , "                result = f(i)(xs[i])(result)"
    , "            return result"
    , "        return step2"
    , "    return step"
    , ""
    , "def foldlWithIndexArray(f):"
    , "    def step(init):"
    , "        def step2(xs):"
    , "            result = init"
    , "            for i, x in enumerate(xs):"
    , "                result = f(i)(result)(x)"
    , "            return result"
    , "        return step2"
    , "    return step"
    ]
  -- Data.TraversableWithIndex
  TIO.writeFile (dir </> "data_traversable_with_index_foreign.py") $ T.unlines
    [ "# FFI for Data.TraversableWithIndex"
    , "def traverseWithIndexArray(apply_):"
    , "    def step(map_):"
    , "        def step2(pure_):"
    , "            def step3(f):"
    , "                def step4(xs):"
    , "                    if len(xs) == 0:"
    , "                        return pure_([])"
    , "                    result = map_(lambda a: [a])(f(0)(xs[0]))"
    , "                    for i, x in enumerate(xs[1:], 1):"
    , "                        result = apply_(map_(lambda arr: lambda a: arr + [a])(result))(f(i)(x))"
    , "                    return result"
    , "                return step4"
    , "            return step3"
    , "        return step2"
    , "    return step"
    ]

-- | Python runtime support code
runtimeCode :: T.Text
runtimeCode = T.unlines
  [ "# PureScript Python Runtime"
  , "# Generated by purepy"
  , ""
  , "__all__ = ['unit', '_runtime_lazy', 'effect_console_log', 'run_effect']"
  , ""
  , "# Unit type"
  , "unit = None"
  , ""
  , "# Lazy initialization wrapper (for mutually recursive bindings)"
  , "def _runtime_lazy(name, module_name, init):"
  , "    state = [0]  # 0=uninit, 1=initializing, 2=done"
  , "    val = [None]"
  , "    def thunk(*args):"
  , "        if state[0] == 2:"
  , "            return val[0]"
  , "        if state[0] == 1:"
  , "            raise RuntimeError(f'{name} was needed before finishing init (module {module_name})')"
  , "        state[0] = 1"
  , "        val[0] = init()"
  , "        state[0] = 2"
  , "        return val[0]"
  , "    return thunk"
  , ""
  , "# Effect.Console.log (convenience alias)"
  , "def effect_console_log(msg):"
  , "    def effect():"
  , "        print(msg)"
  , "        return unit"
  , "    return effect"
  , ""
  , "# Run an effect"
  , "def run_effect(eff):"
  , "    return eff()"
  , ""
  ]
