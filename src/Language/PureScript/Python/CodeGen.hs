{-# OPTIONS_GHC -Wno-name-shadowing #-}

-- |
-- This module generates code in the simplified Python intermediate representation from PureScript code
--
module Language.PureScript.Python.CodeGen
  ( module AST,
    moduleToPy,
  )
where

import Control.Monad (foldM)
import Control.Monad.Error.Class (MonadError (..))
import Control.Monad.Reader (MonadReader (..))
import Control.Monad.Supply.Class (MonadSupply)
import Control.Monad.Writer (MonadWriter (..))
import qualified Data.Text as T
import Data.Traversable (forM)
import qualified Language.PureScript as P
import qualified Language.PureScript.Constants.Prim as C
import Language.PureScript.CoreFn
  ( Ann,
    Bind (..),
    Binder (..),
    CaseAlternative (CaseAlternative),
    Expr (..),
    Literal (..),
    Meta (IsConstructor, IsNewtype, IsTypeClassConstructor),
    Module (Module),
  )
import Language.PureScript.Python.CodeGen.AST as AST
import Language.PureScript.Python.CodeGen.Common
import Language.PureScript.Errors (ErrorMessageHint (..))
import Language.PureScript.Names
  ( Ident (Ident, UnusedIdent),
    ModuleName (..),
    ProperName (ProperName),
    Qualified (..),
  )
import Language.PureScript.Options (Options)
import Language.PureScript.PSString (mkString)
import Language.PureScript.Traversals (sndM)
import Prelude

-- | Simple error type for code generation
type MultipleErrors = [T.Text]

rethrow :: (MonadError MultipleErrors m) => (MultipleErrors -> MultipleErrors) -> m a -> m a
rethrow f action = catchError action (throwError . f)

addHint :: ErrorMessageHint -> MultipleErrors -> MultipleErrors
addHint _ = id  -- Simplified for now

-- | Get the Python name for a qualified identifier
qualifiedToPy :: ModuleName -> Qualified Ident -> T.Text
qualifiedToPy mn (Qualified (P.ByModuleName mn') ident)
  | mn == mn' = identToPyName ident
  | otherwise = pyModuleName mn' PureScriptModule <> "." <> identToPyName ident
qualifiedToPy _ (Qualified (P.BySourcePos _) ident) = identToPyName ident

-- |
-- Generate code in the simplified Python intermediate representation for all declarations in a module.
--
moduleToPy ::
  forall m.
  (Monad m, MonadReader Options m, MonadSupply m, MonadError MultipleErrors m, MonadWriter MultipleErrors m) =>
  Module Ann ->
  [(T.Text, Int)] ->  -- Foreign exports (name, arity)
  m ([T.Text], [Py])  -- (exports, declarations)
moduleToPy (Module _ _ mn _ _ declaredExports _ foreigns decls) _foreignExports =
  rethrow (addHint (ErrorInModule mn)) $ do
    -- Generate code for each binding
    res <- traverse topBindToPy decls

    -- Generate re-exports for foreign imports
    foreignReexports <- traverse reExportForeign foreigns

    let allDecls = concat res ++ concat foreignReexports
        exports = map identToPyName declaredExports

    return (exports, allDecls)
  where
    -- | Re-export a foreign import
    reExportForeign :: Ident -> m [Py]
    reExportForeign ident = do
      let name = identToPyName ident
          foreignModule = pyModuleName mn ForeignModule
          -- Import from foreign module and assign to local name
      return
        [ PyVarBind name (PyAttr (PyVar foreignModule) name)
        ]

    -- | Convert a top-level binding to Python
    topBindToPy :: Bind Ann -> m [Py]
    topBindToPy = \case
      NonRec _ ident val -> do
        py <- valueToPy val
        return [PyVarBind (identToPyName ident) py]
      Rec vals -> do
        -- For recursive bindings, we need to be careful about the order
        -- In Python, we can use a similar approach to Erlang's tuple-of-funs
        -- but lambdas make this easier
        bindings <- forM vals $ \((_, ident), val) -> do
          py <- valueToPy val
          return (identToPyName ident, py)
        return [PyVarBind name py | (name, py) <- bindings]

    -- | Convert a local binding to Python
    bindToPy :: Bind Ann -> m [Py]
    bindToPy (NonRec _ ident val) =
      pure . PyVarBind (identToVar ident) <$> valueToPy val
    bindToPy (Rec vals) = do
      bindings <- forM vals $ \((_, ident), val) -> do
        py <- valueToPy val
        return (identToVar ident, py)
      return [PyVarBind name py | (name, py) <- bindings]

    -- | Convert an expression to Python
    valueToPy :: Expr Ann -> m Py
    valueToPy = \case
      -- Literals
      Literal _ lit -> literalToPy lit

      -- Undefined/unit
      Var _ (Qualified (P.ByModuleName mn') (Ident undef))
        | mn' == C.M_Prim, undef == C.S_undefined ->
          return PyNone

      -- Nullary constructor (constant)
      Var (_, _, Just (IsConstructor _ [])) (Qualified _ ident) ->
        return $ constructorLiteral (identToPyName ident) []

      -- Variable reference
      Var _ ident ->
        return $ PyVar (qualifiedToPy mn ident)

      -- Lambda
      Abs _ arg val -> do
        body <- valueToPy val
        let argName = case arg of
              UnusedIdent -> "_"
              Ident "$__unused" -> "_"
              _ -> identToVar arg
        return $ PyLambda1 argName body

      -- Record accessor
      Accessor _ prop val -> do
        obj <- valueToPy val
        return $ PySubscript obj (PyStringLiteral prop)

      -- Record update
      ObjectUpdate _ o _ ps -> do
        obj <- valueToPy o
        updates <- mapM (sndM valueToPy) ps
        return $ PyDictUpdate obj [(psStringToText k, v) | (k, v) <- updates]

      -- Function application
      e@App{} -> do
        let (f, args) = unApp e []
        args' <- mapM valueToPy args
        case f of
          -- Newtype wrapper (identity)
          Var (_, _, Just IsNewtype) _ ->
            return $ head args'

          -- Constructor application
          Var (_, _, Just (IsConstructor _ fields)) (Qualified _ ident)
            | length args == length fields ->
              return $ constructorLiteral (identToPyName ident) args'

          -- Typeclass constructor
          Var (_, _, Just IsTypeClassConstructor) name -> do
            return $ curriedApp args' $ PyVar (qualifiedToPy mn name)

          -- Regular function application
          _ -> do
            fn <- valueToPy f
            return $ curriedApp args' fn

      -- Case expression
      Case _ values binders -> do
        vals <- mapM valueToPy values
        caseToPy vals binders

      -- Let expression
      Let _ ds val -> do
        bindings <- concat <$> mapM bindToPy ds
        body <- valueToPy val
        -- Wrap in an immediately-invoked lambda to create scope
        return $ iife (bindings ++ [PyReturn body])

      -- Constructor
      Constructor (_, _, Just IsNewtype) _ _ _ ->
        error "newtype ctor should not appear here"
      Constructor _ _ (ProperName ctor) fields ->
        let createFn = foldr (\field e -> PyLambda1 (identToVar field) e)
                             (constructorLiteral (T.pack $ show ctor) (map (PyVar . identToVar) fields))
                             fields
        in pure createFn

      where
        unApp :: Expr Ann -> [Expr Ann] -> (Expr Ann, [Expr Ann])
        unApp (App _ val arg) args = unApp val (arg : args)
        unApp other args = (other, args)

    -- | Create an immediately-invoked function expression
    iife :: [Py] -> Py
    iife stmts = PyApp (PyLambda [] (PyBlock stmts)) []

    -- | Create a constructor tuple: ("CtorName", arg1, arg2, ...)
    constructorLiteral :: T.Text -> [Py] -> Py
    constructorLiteral name args = PyTuple (PyStringLiteral (mkString name) : args)

    -- | Convert a literal to Python
    literalToPy :: Literal (Expr Ann) -> m Py
    literalToPy = \case
      NumericLiteral n -> return $ PyNumericLiteral n
      StringLiteral s -> return $ PyStringLiteral s
      CharLiteral c -> return $ PyStringLiteral (mkString $ T.singleton c)
      BooleanLiteral b -> return $ PyBoolLiteral b
      ArrayLiteral xs -> do
        xs' <- mapM valueToPy xs
        return $ PyList xs'
      ObjectLiteral ps -> do
        ps' <- mapM (sndM valueToPy) ps
        return $ PyRecord [(psStringToText k, v) | (k, v) <- ps']

    -- | Convert case expression to Python match statement
    caseToPy :: [Py] -> [CaseAlternative Ann] -> m Py
    caseToPy vals cases = do
      -- For now, generate if/elif chain
      -- TODO: Use Python 3.10+ match statement where possible
      branches <- mapM (caseAltToPy vals) cases
      return $ ifChain branches

    ifChain :: [(Py, Py)] -> Py
    ifChain [] = PyRaise (PyApp (PyVar "RuntimeError") [PyStringLiteral (mkString "Pattern match failed")])
    ifChain [(cond, body)] = PyIfExp cond body (ifChain [])
    ifChain ((cond, body):rest) = PyIfExp cond body (ifChain rest)

    caseAltToPy :: [Py] -> CaseAlternative Ann -> m (Py, Py)
    caseAltToPy vals (CaseAlternative binders result) = do
      -- Generate pattern matching conditions and bindings
      let binderPairs = zip vals binders
      (conds, bindings) <- foldM processBinderPair ([], []) binderPairs

      let condition = case conds of
            [] -> PyBoolLiteral True
            [c] -> c
            cs -> foldl1 (\a b -> PyBinary And a b) cs

      body <- case result of
        Right e -> valueToPy e
        Left guards -> do
          guardBranches <- forM guards $ \(guardCond, guardBody) -> do
            c <- valueToPy guardCond
            b <- valueToPy guardBody
            return (c, b)
          return $ ifChain guardBranches

      -- Wrap body with bindings if needed
      let wrappedBody = if null bindings
            then body
            else iife (bindings ++ [PyReturn body])

      return (condition, wrappedBody)

    processBinderPair :: ([Py], [Py]) -> (Py, Binder Ann) -> m ([Py], [Py])
    processBinderPair (conds, binds) (val, binder) = do
      (c, b) <- binderToPy val binder
      return (conds ++ c, binds ++ b)

    -- | Convert a binder to conditions and bindings
    binderToPy :: Py -> Binder Ann -> m ([Py], [Py])
    binderToPy _ (NullBinder _) = return ([], [])
    binderToPy val (VarBinder _ ident) =
      return ([], [PyVarBind (identToVar ident) val])
    binderToPy val (LiteralBinder _ lit) = literalBinderToPy val lit
    binderToPy val (ConstructorBinder (_, _, Just IsNewtype) _ _ [b]) =
      binderToPy val b
    binderToPy val (ConstructorBinder _ _ (Qualified _ (ProperName ctorName)) binders) = do
      -- Check constructor tag
      let tagCond = PyBinary EqualTo
                      (PySubscript val (PyNumericLiteral (Left 0)))
                      (PyStringLiteral (mkString $ T.pack $ show ctorName))
      -- Extract fields and process sub-binders
      (subConds, subBinds) <- foldM (processSubBinder val) ([], []) (zip [1..] binders)
      return (tagCond : subConds, subBinds)
    binderToPy val (NamedBinder _ ident binder) = do
      (conds, binds) <- binderToPy val binder
      return (conds, PyVarBind (identToVar ident) val : binds)

    processSubBinder :: Py -> ([Py], [Py]) -> (Int, Binder Ann) -> m ([Py], [Py])
    processSubBinder tupleVal (conds, binds) (idx, binder) = do
      let fieldVal = PySubscript tupleVal (PyNumericLiteral (Left $ toInteger idx))
      (c, b) <- binderToPy fieldVal binder
      return (conds ++ c, binds ++ b)

    literalBinderToPy :: Py -> Literal (Binder Ann) -> m ([Py], [Py])
    literalBinderToPy val = \case
      NumericLiteral n ->
        return ([PyBinary EqualTo val (PyNumericLiteral n)], [])
      StringLiteral s ->
        return ([PyBinary EqualTo val (PyStringLiteral s)], [])
      CharLiteral c ->
        return ([PyBinary EqualTo val (PyStringLiteral (mkString $ T.singleton c))], [])
      BooleanLiteral b ->
        return ([PyBinary EqualTo val (PyBoolLiteral b)], [])
      ArrayLiteral binders -> do
        let lenCheck = PyBinary EqualTo
                        (PyApp (PyVar "len") [val])
                        (PyNumericLiteral (Left $ toInteger $ length binders))
        (subConds, subBinds) <- foldM processArrayBinder ([], []) (zip [0..] binders)
        return (lenCheck : subConds, subBinds)
        where
          processArrayBinder (c, b) (idx, binder) = do
            let elemVal = PySubscript val (PyNumericLiteral (Left idx))
            (c', b') <- binderToPy elemVal binder
            return (c ++ c', b ++ b')
      ObjectLiteral fields -> do
        (subConds, subBinds) <- foldM processFieldBinder ([], []) fields
        return (subConds, subBinds)
        where
          processFieldBinder (c, b) (key, binder) = do
            let fieldVal = PySubscript val (PyStringLiteral key)
            (c', b') <- binderToPy fieldVal binder
            return (c ++ c', b ++ b')
