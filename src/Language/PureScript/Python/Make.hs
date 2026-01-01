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
import Data.Aeson (decodeFileStrict)
import Data.Aeson.Types (parseMaybe)
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
      -- For mutually recursive bindings, use lazy wrappers
      -- 1. Define _lazy_X thunks that capture the init lambdas
      -- 2. Define actual X values by forcing the thunks
      let modName = case currentModule of
            P.ModuleName mn -> mn
          recNames = [identName ident | ((_, ident), _) <- bindings]
          -- Generate _lazy_X = _runtime_lazy(...) for each binding
          lazyDefs = [ "_lazy_" <> identName ident <> " = _runtime_lazy(\"" <> identName ident <> "\", \"" <> modName <> "\", lambda: " <> generateExpr recNames expr <> ")"
                     | ((_, ident), expr) <- bindings
                     ]
          -- Generate X = _lazy_X() to force evaluation
          valueDefs = [ identName ident <> " = _lazy_" <> identName ident <> "()"
                      | ((_, ident), _) <- bindings
                      ]
      in T.unlines (lazyDefs ++ valueDefs)

    identName :: P.Ident -> T.Text
    identName = identToPyName

    -- | Generate expression, tracking names in current Rec group for thunk calls
    generateExpr :: [T.Text] -> CoreFn.Expr CoreFn.Ann -> T.Text
    generateExpr recNames = \case
      CoreFn.Literal _ lit -> generateLiteral recNames lit
      CoreFn.Var _ qi -> generateQualifiedIdent recNames qi
      CoreFn.Abs _ arg body ->
        "(lambda " <> identName arg <> ": " <> generateExpr recNames body <> ")"
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
        Left _ -> rest  -- Guarded case not yet implemented
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
    generatePattern _ scrutinee (CoreFn.LiteralBinder _ lit) =
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
        CoreFn.ArrayLiteral _ ->
          ("True", [])  -- TODO: array pattern matching
        CoreFn.ObjectLiteral _ ->
          ("True", [])  -- TODO: object pattern matching
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
