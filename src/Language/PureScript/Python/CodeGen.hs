{-# LANGUAGE OverloadedStrings #-}

-- |
-- CoreFn -> Python code generation (direct text emission).
--
-- The architecture is the sibling Jurist backend's (purejl), which was
-- itself cribbed from this repo's first incarnation - the skeleton comes
-- home. Python is statement-oriented with expression-only lambdas, so
-- where Julia uses @begin@/@end@ IIFEs this backend uses two verified
-- expression idioms plus one structural move:
--
--   * let-scoping: @(lambda: ((x := e1), (y := e2), body)[-1])()@ -
--     walrus bindings sequenced in a tuple, the trailing element is the
--     value, the wrapping lambda confines the bindings (a bare walrus
--     would poison the whole enclosing scope - see the pattern-binding
--     note below).
--   * alternatives: chained conditional expressions
--     @(body if cond else rest)@.
--   * lambda lifting: every CoreFn @Abs@ is hoisted to a module-level
--     one-line @def@, with its free LOCAL variables passed explicitly
--     (module-level names are Python globals inside defs and need no
--     passing). The use site is the def's name, or
--     @_mk(_lamN, free1, ...)@ (runtime helper currying the environment
--     back to a unary closure). This is load-bearing, not cosmetic:
--     CPython's tokenizer caps paren nesting at ~200 and indentation at
--     100, so a long monadic do-chain (each bind nesting its
--     continuation lambda inside a call) is a SyntaxError if emitted
--     inline. Lifting turns continuation depth into flat sibling defs.
--
-- Lifting captures free variables BY VALUE at closure-creation time,
-- which is exactly CoreFn semantics for everything except recursive
-- LOCAL bindings, where the name must resolve late (it is not bound yet
-- when its own lambda is created). Those keep their outermost lambda
-- chain inline - Python closures look free names up at call time - and
-- lift only inside the body (safe: by the time the body runs, the
-- binding is complete). Top-level recursion needs no care: module-level
-- names are globals, and defs read globals late.
--
-- Representation choices (mirroring Jurist ADR-0001, 0-based):
--
--   * ADT values are tag-tuples: @("Just", x)@, nullary @("Nothing",)@.
--     Tag at index 0, fields from index 1.
--   * Newtype constructors are identity functions.
--   * Typeclass dictionaries are dicts keyed by member name, so CoreFn's
--     @Accessor@ works uniformly.
--   * Records are dicts; update is @{**rec, "k": v}@.
--   * Arrays are lists.
--   * Effects are zero-argument closures (thunks).
--   * Functions are curried unary closures; application is @(f)(x)(y)@.
--
-- Pattern bindings are confined to a per-alternative IIFE: a walrus
-- binding anywhere in a lambda makes that name local THROUGHOUT the
-- lambda, so binding a pattern variable directly inside the case
-- dispatch lambda would shadow an outer binding of the same name for
-- EVERY alternative (UnboundLocalError when another alternative reads
-- the outer name). The per-alternative @(lambda: (binds..., body)[-1])()@
-- restores Julia's IIFE scoping exactly.
--
-- Tail-call optimization (the trampoline):
--
-- CPython has a ~1000-frame recursion limit and no TCO, so - mirroring
-- what purs itself does for JS in CoreImp.Optimizer.TCO - bindings whose
-- self-references are ALL fully-saturated tail calls are compiled to a
-- dispatch loop:
--
-- > f = (lambda _tco_loop:
-- >        (lambda x1: (lambda x2: _tco_run(_tco_loop, (x1, x2,)))))
-- >      (lambda x1, x2: <body with self-calls as (1, (args,)) and
-- >                       results as (0, value)>)
--
-- where @_tco_run@ (runtime) is the while loop. The
-- function-call-per-iteration shape (rather than rebinding loop
-- variables in place) is deliberate, again following purs: closures
-- created in the loop body must capture per-iteration bindings. Applies
-- to top-level Rec groups (self-recursion arrives as singleton Rec) and
-- let-bound Rec groups (the ubiquitous local @go@). The loop body never
-- references the binding itself (self-calls become tuples), so it lifts
-- like any other code.
--
-- Known v1 limitations (as Jurist):
--
--   * Mutual recursion is not trampolined (matches the JS backend, where
--     MonadRec is the idiom for unbounded non-self recursion).
--   * Paren nesting still grows linearly with the number of alternatives
--     in a single case (ternary chain) and with right-nested operator
--     chains; both are bounded far below the tokenizer limit in
--     practice.
--
module Language.PureScript.Python.CodeGen
  ( generateModulePy
  ) where

import Prelude

import Control.Monad.State.Strict (State, evalState, get, modify, put)
import Data.List (partition)
import qualified Data.Set as Set
import qualified Data.Text as T

import qualified Language.PureScript as P
import qualified Language.PureScript.CoreFn as CoreFn
import Language.PureScript.PSString (PSString, decodeString)

import Language.PureScript.Python.CodeGen.Common

-- | Code generation state: fresh-name counter and lifted module-level
-- defs awaiting flush (emitted before the top-level binding being
-- compiled).
type Gen = State (Int, [T.Text])

fresh :: Gen T.Text
fresh = do
  (i, ds) <- get
  put (i + 1, ds)
  pure ("_lam" <> T.pack (show i))

emitDef :: T.Text -> Gen ()
emitDef d = modify (\(i, ds) -> (i, ds ++ [d]))

flushDefs :: Gen [T.Text]
flushDefs = do
  (i, ds) <- get
  put (i, [])
  pure ds

-- | Locally-bound (function-scope) names currently in scope; used to
-- compute the free variables a lifted lambda must close over.
type Env = Set.Set T.Text

-- | Generate the Python body (declarations only, no module header) for a module
generateModulePy :: CoreFn.Module CoreFn.Ann -> T.Text
generateModulePy cfModule =
  T.unlines $ evalState (concat <$> mapM genTop (CoreFn.moduleDecls cfModule)) (0, [])
  where
    genTop :: CoreFn.Bind CoreFn.Ann -> Gen [T.Text]
    genTop b = do
      txt <- generateBinding b
      ds <- flushDefs
      pure (ds ++ [txt])

    currentModule :: P.ModuleName
    currentModule = CoreFn.moduleName cfModule

    currentModuleText :: T.Text
    currentModuleText = case currentModule of
      P.ModuleName mn -> mn

    -- | Generate a top-level binding, tracking names in the current Rec group
    generateBinding :: CoreFn.Bind CoreFn.Ann -> Gen T.Text
    generateBinding (CoreFn.NonRec _ ident expr) = do
      rhs <- generateInlineAbs Set.empty [] expr
      pure (identName ident <> " = " <> rhs)
    generateBinding (CoreFn.Rec bindings) = do
      -- Rec handling, in order of preference per binding:
      --   1. TCO: all self-refs are saturated tail calls -> dispatch loop,
      --      plain assignment, no thunk (other-member refs resolve at call
      --      time, or through _lazy_X() for thunked members).
      --   2. Function bindings (RHS is a lambda chain): plain assignment,
      --      no thunk. A lambda evaluates nothing at definition time, and
      --      Python resolves module-global names at CALL time, so self and
      --      mutual recursion through function bodies needs no indirection.
      --      (A per-call _lazy_f() here is pure overhead - measured ~25%
      --      of fib's runtime.)
      --   3. Smart thunk partition for VALUE bindings: only those that
      --      reference remaining group members go through the lazy-thunk
      --      runtime.
      let tcoAnnotated = [ (b, tryTco (identName ident) expr)
                         | b@((_, ident), expr) <- bindings ]
          tcoBindings = [ (ident, ps, body)
                        | (((_, ident), _), Just (ps, body)) <- tcoAnnotated ]
          plainBindings = [ b | (b, Nothing) <- tcoAnnotated ]
          isFunction (_, expr) = case expr of
            CoreFn.Abs {} -> True
            _ -> False
          (functions, values) = partition isFunction plainBindings
          valueNames = Set.fromList [identName ident | ((_, ident), _) <- values]
          needsThunk ((_, _ident), expr) =
            not $ Set.null $ Set.intersection (collectLocalRefs currentModule expr) valueNames
          (recursive, nonRecursive) = partition needsThunk values
          recNames = [identName ident | ((_, ident), _) <- recursive]
      tcoDefs <- mapM (\(ident, ps, body) -> do
                        rhs <- generateTcoExpr Set.empty recNames (identName ident) ps body
                        pure (identName ident <> " = " <> rhs))
                      tcoBindings
      funDefs <- mapM (\((_, ident), expr) -> do
                        rhs <- generateInlineAbs Set.empty recNames expr
                        pure (identName ident <> " = " <> rhs))
                      functions
      nonRecDefs <- mapM (\((_, ident), expr) -> do
                           rhs <- generateInlineAbs Set.empty recNames expr
                           pure (identName ident <> " = " <> rhs))
                         nonRecursive
      lazyDefs <- mapM (\((_, ident), expr) -> do
                         rhs <- generateExpr Set.empty recNames expr
                         pure ("_lazy_" <> identName ident
                               <> " = _runtime_lazy(\"" <> identName ident <> "\", \""
                               <> escapeStringPy currentModuleText <> "\", lambda: "
                               <> rhs <> ")"))
                       recursive
      let valueDefs = [ identName ident <> " = _lazy_" <> identName ident <> "()"
                      | ((_, ident), _) <- recursive
                      ]
      pure (T.unlines (tcoDefs ++ funDefs ++ nonRecDefs ++ lazyDefs ++ valueDefs))

    identName :: P.Ident -> T.Text
    identName = identToPyName

    -- | Compile an outermost Abs chain inline (curried literal lambdas)
    -- rather than lifting it. Used where late binding of the name being
    -- defined is required (recursive local bindings) and at top-level
    -- binding roots (where lifting would only add an alias line).
    generateInlineAbs :: Env -> [T.Text] -> CoreFn.Expr CoreFn.Ann -> Gen T.Text
    generateInlineAbs env recNames (CoreFn.Abs _ arg body) = do
      let p = identName arg
      inner <- generateInlineAbs (Set.insert p env) recNames body
      pure ("(lambda " <> p <> ": " <> inner <> ")")
    generateInlineAbs env recNames other = generateExpr env recNames other

    -- | Generate an expression. @env@ tracks locally-bound names for
    -- free-variable analysis; @recNames@ tracks the current top-level
    -- Rec group (references go through their lazy thunks).
    generateExpr :: Env -> [T.Text] -> CoreFn.Expr CoreFn.Ann -> Gen T.Text
    generateExpr env recNames = \case
      CoreFn.Literal _ lit -> generateLiteral env recNames lit

      -- Prim.undefined
      CoreFn.Var _ (P.Qualified (P.ByModuleName (P.ModuleName "Prim")) (P.Ident "undefined")) ->
        pure "None"

      CoreFn.Var _ qi -> pure (generateQualifiedIdent recNames qi)

      CoreFn.Abs _ arg body -> liftAbs env recNames arg body

      CoreFn.App _ fn arg -> do
        f <- generateExpr env recNames fn
        a <- generateExpr env recNames arg
        pure ("(" <> f <> ")(" <> a <> ")")

      CoreFn.Let _ binds body -> do
        (env', stmts) <- generateLetBinds env recNames binds
        b <- generateExpr env' recNames body
        pure (iife stmts b)

      CoreFn.Case _ exprs alts ->
        generateCase env recNames generateExpr exprs alts

      CoreFn.Accessor _ field expr -> do
        e <- generateExpr env recNames expr
        pure ("(" <> e <> ")[\"" <> psStringToText field <> "\"]")

      CoreFn.ObjectUpdate _ expr _ updates -> do
        e <- generateExpr env recNames expr
        us <- mapM (\(k, v) -> do
                     v' <- generateExpr env recNames v
                     pure ("\"" <> psStringToText k <> "\": " <> v'))
                   updates
        pure ("{**(" <> e <> "), " <> T.intercalate ", " us <> "}")

      CoreFn.Constructor ann _ (P.ProperName ctor) fields ->
        pure (constructorToPy ann ctor fields)

    -- | Hoist a lambda to a module-level def, closing over its free
    -- local variables explicitly.
    liftAbs :: Env -> [T.Text] -> P.Ident -> CoreFn.Expr CoreFn.Ann -> Gen T.Text
    liftAbs env recNames arg body = do
      let param = identName arg
          free = Set.toAscList
                   (Set.intersection
                     (Set.delete param (collectLocalRefs currentModule body))
                     env)
          env' = Set.fromList (free ++ [param])
      bodyTxt <- generateExpr env' recNames body
      name <- fresh
      emitDef ("def " <> name <> "(" <> T.intercalate ", " (free ++ [param])
               <> "): return " <> bodyTxt)
      pure $ if null free
        then name
        else "_mk(" <> name <> ", " <> T.intercalate ", " free <> ")"

    -- | Shared case compilation: dispatch lambda over the (tupled)
    -- scrutinee, alternatives as a ternary chain. Parameterized by the
    -- body compiler so the TCO tail compilation reuses the whole
    -- pattern apparatus.
    generateCase :: Env -> [T.Text]
                 -> (Env -> [T.Text] -> CoreFn.Expr CoreFn.Ann -> Gen T.Text)
                 -> [CoreFn.Expr CoreFn.Ann] -> [CoreFn.CaseAlternative CoreFn.Ann]
                 -> Gen T.Text
    generateCase env recNames compileBody exprs alts = do
      (scrutCode, roots) <- scrutinize env recNames exprs
      altsCode <- foldr (\alt rest -> do
                          restCode <- rest
                          generateAlt env recNames roots compileBody alt restCode)
                        (pure failCase) alts
      pure ("(lambda __v__: " <> altsCode <> ")(" <> scrutCode <> ")")

    -- | Scrutinee expression and per-binder root expressions for a case.
    -- Multiple scrutinees are tupled; roots index the tuple (0-based).
    scrutinize :: Env -> [T.Text] -> [CoreFn.Expr CoreFn.Ann] -> Gen (T.Text, [T.Text])
    scrutinize env recNames = \case
      [e] -> do
        s <- generateExpr env recNames e
        pure (s, ["__v__"])
      es -> do
        ss <- mapM (generateExpr env recNames) es
        pure ( "(" <> T.intercalate ", " ss <> ")"
             , [ "__v__[" <> T.pack (show i) <> "]" | i <- [0 .. length es - 1] ]
             )

    -- | Constructor declarations.
    constructorToPy :: CoreFn.Ann -> T.Text -> [P.Ident] -> T.Text
    constructorToPy ann ctor fields = case ann of
      -- Newtype constructor: identity
      (_, _, Just CoreFn.IsNewtype) -> "(lambda __x: __x)"
      -- Typeclass dictionary constructor: build a record keyed by member
      -- name so Accessor works on the result
      (_, _, Just CoreFn.IsTypeClassConstructor) ->
        let dict = "{"
                   <> T.intercalate ", " [ "\"" <> escapeStringPy (runIdent' f) <> "\": " <> identName f
                                         | f <- fields ]
                   <> "}"
        in curriedOver fields dict
      -- Data constructor: curried tag-tuple builder
      _ ->
        let tup = if null fields
                    then "(\"" <> escapeStringPy ctor <> "\",)"
                    else "(\"" <> escapeStringPy ctor <> "\", "
                         <> T.intercalate ", " (map identName fields) <> ")"
        in curriedOver fields tup

    curriedOver :: [P.Ident] -> T.Text -> T.Text
    curriedOver fields body =
      foldr (\f acc -> "(lambda " <> identName f <> ": " <> acc <> ")") body fields

    -- | Let bindings become walrus statements inside an IIFE; returns
    -- the extended environment for the body. Local (mutual) recursion:
    -- non-TCO recursive bindings keep their outermost lambda chain
    -- inline so the recursive name resolves late (call time), by which
    -- point every member of the group is bound.
    generateLetBinds :: Env -> [T.Text] -> [CoreFn.Bind CoreFn.Ann] -> Gen (Env, [T.Text])
    generateLetBinds env recNames = go env []
      where
        go e acc [] = pure (e, acc)
        go e acc (CoreFn.NonRec _ ident expr : rest) = do
          rhs <- generateExpr e recNames expr
          let name = identName ident
          go (Set.insert name e) (acc ++ ["(" <> name <> " := " <> rhs <> ")"]) rest
        go e acc (CoreFn.Rec bindings : rest) = do
          let names = [identName ident | ((_, ident), _) <- bindings]
              e' = foldr Set.insert e names
          stmts <- mapM (\((_, ident), expr) ->
                          case tryTco (identName ident) expr of
                            Just (ps, body) -> do
                              rhs <- generateTcoExpr e' recNames (identName ident) ps body
                              pure ("(" <> identName ident <> " := " <> rhs <> ")")
                            Nothing -> do
                              rhs <- generateInlineAbs e' recNames expr
                              pure ("(" <> identName ident <> " := " <> rhs <> ")"))
                        bindings
          go e' (acc ++ stmts) rest

    -- | Expression-position statement scope: walrus bindings sequenced in
    -- a tuple inside a lambda (which confines them), trailing element is
    -- the value.
    iife :: [T.Text] -> T.Text -> T.Text
    iife [] body = body
    iife stmts body =
      "(lambda: (" <> T.intercalate ", " stmts <> ", " <> body <> ")[-1])()"

    failCase :: T.Text
    failCase = "_pattern_fail(\"" <> escapeStringPy currentModuleText <> "\")"

    -- | One alternative, chaining to @rest@ on no-match (or guard
    -- fall-through).
    generateAlt :: Env -> [T.Text] -> [T.Text]
                -> (Env -> [T.Text] -> CoreFn.Expr CoreFn.Ann -> Gen T.Text)
                -> CoreFn.CaseAlternative CoreFn.Ann -> T.Text -> Gen T.Text
    generateAlt env recNames roots compileBody (CoreFn.CaseAlternative binders result) rest = do
      let patResults = zipWith generatePattern roots binders
          conds = filter (/= "True") (map fst patResults)
          allBindings = concatMap snd patResults
          boundNames = concatMap binderBoundNames binders
          env' = foldr Set.insert env boundNames
          combinedCond = case conds of
            [] -> "True"
            _ -> T.intercalate " and " conds
      bodyCode <- case result of
        Right body -> compileBody env' recNames body
        Left guards ->
          let generateGuards [] = pure rest
              generateGuards ((g, b):gs) = do
                g' <- generateExpr env' recNames g
                b' <- compileBody env' recNames b
                rest' <- generateGuards gs
                pure ("(" <> b' <> " if " <> g' <> " else " <> rest' <> ")")
          in generateGuards guards
      let withBindings = if null allBindings
                           then bodyCode
                           else iife allBindings bodyCode
      pure $ if combinedCond == "True"
        then withBindings
        else "(" <> withBindings <> " if " <> combinedCond <> " else " <> rest <> ")"

    -- | Names bound by a binder (for environment extension)
    binderBoundNames :: CoreFn.Binder CoreFn.Ann -> [T.Text]
    binderBoundNames = \case
      CoreFn.VarBinder _ ident -> [identName ident]
      CoreFn.NullBinder _ -> []
      CoreFn.LiteralBinder _ lit -> case lit of
        CoreFn.ArrayLiteral bs -> concatMap binderBoundNames bs
        CoreFn.ObjectLiteral fs -> concatMap (binderBoundNames . snd) fs
        _ -> []
      CoreFn.ConstructorBinder _ _ _ subs -> concatMap binderBoundNames subs
      CoreFn.NamedBinder _ ident inner -> identName ident : binderBoundNames inner

    -- | Generate (condition, [walrus binding statements]) for a binder
    -- against a scrutinee expression
    generatePattern :: T.Text -> CoreFn.Binder CoreFn.Ann -> (T.Text, [T.Text])
    generatePattern scrutinee (CoreFn.VarBinder _ ident) =
      ("True", ["(" <> identName ident <> " := " <> scrutinee <> ")"])
    generatePattern _ (CoreFn.NullBinder _) =
      ("True", [])
    generatePattern scrutinee (CoreFn.LiteralBinder _ lit) =
      case lit of
        CoreFn.NumericLiteral (Left n) ->
          (scrutinee <> " == " <> T.pack (show n), [])
        CoreFn.NumericLiteral (Right n) ->
          (scrutinee <> " == " <> T.pack (show n), [])
        CoreFn.StringLiteral s ->
          (scrutinee <> " == \"" <> psStringToText s <> "\"", [])
        CoreFn.CharLiteral c ->
          (scrutinee <> " == \"" <> escapeCharPy c <> "\"", [])
        CoreFn.BooleanLiteral True ->
          (scrutinee <> " == True", [])
        CoreFn.BooleanLiteral False ->
          (scrutinee <> " == False", [])
        CoreFn.ArrayLiteral binders ->
          let lenCheck = "_len(" <> scrutinee <> ") == " <> T.pack (show (length binders))
              elemPatterns = zipWith
                (\i b -> generatePattern (scrutinee <> "[" <> T.pack (show (i :: Int)) <> "]") b)
                [0..] binders
              elemConds = filter (/= "True") $ map fst elemPatterns
              elemBindings = concatMap snd elemPatterns
              combinedCond = T.intercalate " and " (lenCheck : elemConds)
          in (combinedCond, elemBindings)
        CoreFn.ObjectLiteral fields ->
          let fieldPatterns = map
                (\(fieldName, binder) ->
                   generatePattern (scrutinee <> "[\"" <> psKey fieldName <> "\"]") binder)
                fields
              fieldConds = filter (/= "True") $ map fst fieldPatterns
              fieldBindings = concatMap snd fieldPatterns
              combinedCond = case fieldConds of
                [] -> "True"
                _ -> T.intercalate " and " fieldConds
          in (combinedCond, fieldBindings)
    generatePattern scrutinee (CoreFn.ConstructorBinder ann _tyName (P.Qualified _ (P.ProperName ctorName)) subBinders) =
      case ann of
        (_, _, Just CoreFn.IsNewtype) ->
          -- Newtype: the value IS the wrapped value
          case subBinders of
            [inner] -> generatePattern scrutinee inner
            _ -> ("True", [])
        _ ->
          -- Tag at [0], fields from [1]
          let tagCheck = scrutinee <> "[0] == \"" <> escapeStringPy ctorName <> "\""
              fieldPatterns = zipWith
                (\i b -> generatePattern (scrutinee <> "[" <> T.pack (show (i :: Int)) <> "]") b)
                [1..] subBinders
              fieldConds = filter (/= "True") $ map fst fieldPatterns
              fieldBindings = concatMap snd fieldPatterns
              combinedCond = T.intercalate " and " (tagCheck : fieldConds)
          in (combinedCond, fieldBindings)
    generatePattern scrutinee (CoreFn.NamedBinder _ ident inner) =
      let (innerCond, innerBindings) = generatePattern scrutinee inner
          binding = "(" <> identName ident <> " := " <> scrutinee <> ")"
      in (innerCond, binding : innerBindings)

    -- ---------------------------------------------------------------
    -- Tail-call optimization
    -- ---------------------------------------------------------------

    unApp :: CoreFn.Expr CoreFn.Ann -> (CoreFn.Expr CoreFn.Ann, [CoreFn.Expr CoreFn.Ann])
    unApp = go []
      where
        go args (CoreFn.App _ fn arg) = go (arg : args) fn
        go args other = (other, args)

    peelAbs :: CoreFn.Expr CoreFn.Ann -> ([P.Ident], CoreFn.Expr CoreFn.Ann)
    peelAbs (CoreFn.Abs _ arg body) =
      let (ps, b) = peelAbs body in (arg : ps, b)
    peelAbs other = ([], other)

    -- | Is this expression a Var referring to the named local binding?
    isSelfVar :: T.Text -> CoreFn.Expr CoreFn.Ann -> Bool
    isSelfVar self (CoreFn.Var _ (P.Qualified qb ident)) =
      identName ident == self && case qb of
        P.ByModuleName mn -> mn == currentModule
        P.BySourcePos _ -> True
    isSelfVar _ _ = False

    -- | TCO applicability: the binding must be a lambda chain whose body
    -- references itself ONLY as fully-saturated tail calls (and at least
    -- once). Returns the peeled params and body when applicable.
    tryTco :: T.Text -> CoreFn.Expr CoreFn.Ann -> Maybe ([P.Ident], CoreFn.Expr CoreFn.Ann)
    tryTco self expr =
      let (params, body) = peelAbs expr
          n = length params
      in if n > 0 && hasSelfTailCall self n body && tcoOk self n True body
           then Just (params, body)
           else Nothing

    -- | Does any tail position contain a saturated self call?
    hasSelfTailCall :: T.Text -> Int -> CoreFn.Expr CoreFn.Ann -> Bool
    hasSelfTailCall self n = go
      where
        go expr = case expr of
          e@(CoreFn.App {}) ->
            let (fn, args) = unApp e
            in isSelfVar self fn && length args == n
          CoreFn.Case _ _ alts ->
            let altHas (CoreFn.CaseAlternative _ result) = case result of
                  Right b -> go b
                  Left guards -> any (go . snd) guards
            in any altHas alts
          CoreFn.Let _ _ body -> go body
          _ -> False

    -- | Walk with a tail-position flag; False means disqualified. Self
    -- references are only allowed as exact-arity applications in tail
    -- position; a self reference inside a nested lambda, an argument, a
    -- scrutinee, a guard condition, or a let RHS disqualifies.
    tcoOk :: T.Text -> Int -> Bool -> CoreFn.Expr CoreFn.Ann -> Bool
    tcoOk self n = go
      where
        noSelf e = not (Set.member self (collectLocalRefs currentModule e))
        go tailPos expr = case expr of
          e@(CoreFn.App {}) ->
            let (fn, args) = unApp e
            in if isSelfVar self fn
                 then tailPos && length args == n && all (go False) args
                 else go False fn && all (go False) args
          v@(CoreFn.Var {}) -> not (isSelfVar self v)
          CoreFn.Abs _ _ body -> noSelf body
          CoreFn.Case _ scruts alts ->
            let altOk (CoreFn.CaseAlternative _ result) = case result of
                  Right b -> go tailPos b
                  Left guards -> all (\(g, b) -> go False g && go tailPos b) guards
            in all (go False) scruts && all altOk alts
          CoreFn.Let _ binds body ->
            let bindOk (CoreFn.NonRec _ _ e) = go False e
                bindOk (CoreFn.Rec bs) = all (go False . snd) bs
            in all bindOk binds && go tailPos body
          CoreFn.Accessor _ _ e -> go False e
          CoreFn.ObjectUpdate _ e _ updates ->
            go False e && all (go False . snd) updates
          CoreFn.Literal _ lit -> case lit of
            CoreFn.ArrayLiteral es -> all (go False) es
            CoreFn.ObjectLiteral fs -> all (go False . snd) fs
            _ -> True
          CoreFn.Constructor {} -> True

    -- | Rename earlier duplicates in a param list (shadowed/unused
    -- params); the body only ever sees the last occurrence.
    uniquifyParams :: [T.Text] -> [T.Text]
    uniquifyParams = go (0 :: Int)
      where
        go _ [] = []
        go i (name : rest)
          | name `elem` rest = (name <> "__" <> T.pack (show i)) : go (i + 1) rest
          | otherwise = name : go (i + 1) rest

    -- | Emit the trampolined form (a single expression, one line). The
    -- loop body contains no reference to the binding itself (self-calls
    -- become tuples), so the surrounding scope's late binding is never
    -- needed inside it.
    generateTcoExpr :: Env -> [T.Text] -> T.Text -> [P.Ident] -> CoreFn.Expr CoreFn.Ann -> Gen T.Text
    generateTcoExpr env recNames self params body = do
      let names = uniquifyParams (map identName params)
          n = length names
          envLoop = foldr Set.insert env names
      tailTxt <- generateTailExpr envLoop recNames self n body
      let loopLambda = "lambda " <> T.intercalate ", " names <> ": " <> tailTxt
          runCall = "_tco_run(_tco_loop, (" <> T.intercalate ", " names <> ",))"
          wrapper = foldr (\p acc -> "(lambda " <> p <> ": " <> acc <> ")") runCall names
      pure ("(lambda _tco_loop: " <> wrapper <> ")(" <> loopLambda <> ")")

    -- | Compile an expression in tail position of a TCO loop function.
    -- Every control path evaluates to @(1, (args,))@ (loop again),
    -- @(0, value)@ (done), or a raised pattern-match error. Stays in
    -- expression land: case dispatch lambdas nest and shadow @__v__@
    -- naturally, so no depth numbering is needed.
    generateTailExpr :: Env -> [T.Text] -> T.Text -> Int -> CoreFn.Expr CoreFn.Ann -> Gen T.Text
    generateTailExpr env recNames self n expr = case expr of
      e@(CoreFn.App {})
        | (fn, args) <- unApp e
        , isSelfVar self fn
        , length args == n -> do
          args' <- mapM (generateExpr env recNames) args
          pure ("(1, (" <> T.intercalate ", " args' <> ",))")
      CoreFn.Let _ binds body -> do
        (env', stmts) <- generateLetBinds env recNames binds
        b <- generateTailExpr env' recNames self n body
        pure (iife stmts b)
      CoreFn.Case _ scruts alts ->
        generateCase env recNames
          (\e rn b -> generateTailExpr e rn self n b)
          scruts alts
      other -> do
        e <- generateExpr env recNames other
        pure ("(0, " <> e <> ")")

    generateLiteral :: Env -> [T.Text] -> CoreFn.Literal (CoreFn.Expr CoreFn.Ann) -> Gen T.Text
    generateLiteral env recNames = \case
      CoreFn.NumericLiteral (Left n) -> pure (T.pack (show n))
      CoreFn.NumericLiteral (Right n) -> pure (T.pack (show n))
      CoreFn.StringLiteral s -> pure ("\"" <> psStringToText s <> "\"")
      CoreFn.CharLiteral c -> pure ("\"" <> escapeCharPy c <> "\"")
      CoreFn.BooleanLiteral True -> pure "True"
      CoreFn.BooleanLiteral False -> pure "False"
      CoreFn.ArrayLiteral exprs -> do
        es <- mapM (generateExpr env recNames) exprs
        pure ("[" <> T.intercalate ", " es <> "]")
      CoreFn.ObjectLiteral fields -> do
        fs <- mapM (\(k, v) -> do
                     v' <- generateExpr env recNames v
                     pure ("\"" <> psStringToText k <> "\": " <> v'))
                   fields
        pure ("{" <> T.intercalate ", " fs <> "}")

    psKey :: PSString -> T.Text
    psKey s = case decodeString s of
      Just str -> escapeStringPy str
      Nothing -> psStringToText s

    generateQualifiedIdent :: [T.Text] -> P.Qualified P.Ident -> T.Text
    generateQualifiedIdent recNames (P.Qualified qb ident) =
      let name = identName ident
          -- Names in the current Rec group go through their lazy thunk
          maybeCallLazyThunk n = if n `elem` recNames then "_lazy_" <> n <> "()" else n
      in case qb of
        P.ByModuleName mn
          | mn == currentModule -> maybeCallLazyThunk name
          | otherwise -> pyModuleName mn <> "." <> name
        P.BySourcePos _ -> maybeCallLazyThunk name

-- | Collect all references to local (same-module or source-pos-qualified)
-- names from an expression - used for smart Rec partitioning and for the
-- free-variable analysis behind lambda lifting (intersected with the
-- bound-locals environment, so over-approximation is safe).
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
