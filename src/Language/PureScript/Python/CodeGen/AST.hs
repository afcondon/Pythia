{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PatternSynonyms #-}

-- |
-- Data types for the intermediate simplified-Python AST
--
module Language.PureScript.Python.CodeGen.AST where

import Prelude

import Data.Text (Text)

import Control.Monad.Identity
import Control.Arrow (second)

import Language.PureScript.PSString (PSString)
import Language.PureScript.AST.SourcePos

-- |
-- Data type for simplified Python expressions
--
data Py
  -- |
  -- A numeric literal (integer or float)
  --
  = PyNumericLiteral (Either Integer Double)
  -- |
  -- A string literal
  --
  | PyStringLiteral PSString
  -- |
  -- A boolean literal
  --
  | PyBoolLiteral Bool
  -- |
  -- None literal
  --
  | PyNone
  -- |
  -- A unary operator application
  --
  | PyUnary UnaryOperator Py
  -- |
  -- A binary operator application
  --
  | PyBinary BinaryOperator Py Py
  -- |
  -- Top-level function definition: def name(args): body
  --
  | PyFunctionDef (Maybe PyType) (Maybe SourceSpan) Text [Text] Py
  -- |
  -- Variable binding: name = value
  --
  | PyVarBind Text Py
  -- |
  -- A variable reference
  --
  | PyVar Text
  -- |
  -- Lambda expression: lambda args: body
  --
  | PyLambda [Text] Py
  -- |
  -- Function application: f(args)
  --
  | PyApp Py [Py]
  -- |
  -- Method call: obj.method(args)
  --
  | PyMethodCall Py Text [Py]
  -- |
  -- Attribute access: obj.attr
  --
  | PyAttr Py Text
  -- |
  -- Block of statements (function body, etc.)
  --
  | PyBlock [Py]
  -- |
  -- Return statement
  --
  | PyReturn Py
  -- |
  -- Tuple literal: (a, b, c)
  --
  | PyTuple [Py]
  -- |
  -- List literal: [a, b, c]
  --
  | PyList [Py]
  -- |
  -- Dict literal: {"key": value, ...}
  --
  | PyDict [(Py, Py)]
  -- |
  -- Dict with string keys (for records): {"key": value, ...}
  --
  | PyRecord [(Text, Py)]
  -- |
  -- Dict update: {**old, "key": value}
  --
  | PyDictUpdate Py [(Text, Py)]
  -- |
  -- Subscript: obj[key]
  --
  | PySubscript Py Py
  -- |
  -- If expression (ternary): value if cond else other
  --
  | PyIfExp Py Py Py
  -- |
  -- If statement: if cond: body elif cond2: body2 else: body3
  --
  | PyIf [(Py, Py)] (Maybe Py)
  -- |
  -- Match statement (Python 3.10+): match expr: case pattern: body
  --
  | PyMatch Py [(PyPattern, Maybe Py, Py)]
  -- |
  -- Comment
  --
  | PyComment Text
  -- |
  -- Import statement: from module import name
  --
  | PyFromImport Text [Text]
  -- |
  -- Import statement: import module
  --
  | PyImport Text
  -- |
  -- Raise exception
  --
  | PyRaise Py
  -- |
  -- Pass statement
  --
  | PyPass
  -- |
  -- Class definition (for ADTs)
  --
  | PyClass Text (Maybe Text) [Py]
  -- |
  -- Decorated definition
  --
  | PyDecorated Text Py

  deriving (Show, Eq)

-- |
-- Pattern for match statements
--
data PyPattern
  = PyPatternVar Text           -- x (binds variable)
  | PyPatternWildcard           -- _
  | PyPatternLiteral Py         -- 1, "foo", True
  | PyPatternTuple [PyPattern]  -- (a, b, c)
  | PyPatternList [PyPattern]   -- [a, b, c]
  | PyPatternCtor Text [PyPattern]  -- CtorName(a, b)
  | PyPatternAs PyPattern Text  -- pattern as name
  | PyPatternOr [PyPattern]     -- pattern1 | pattern2
  deriving (Show, Eq)

-- | Helper pattern for simple single-argument lambda
pattern PyLambda1 :: Text -> Py -> Py
pattern PyLambda1 var e = PyLambda [var] e

-- | Build a curried lambda from a list of arguments
curriedLambda :: Py -> [Text] -> Py
curriedLambda = foldr (\v e -> PyLambda1 v e)

-- | Build curried application
curriedApp :: [Py] -> Py -> Py
curriedApp = flip (foldl (\fn a -> PyApp fn [a]))

-- |
-- Built-in unary operators
--
data UnaryOperator
  = Negate      -- -x
  | Not         -- not x
  | BitwiseNot  -- ~x
  | Positive    -- +x
  deriving (Show, Eq)

-- |
-- Built-in binary operators
--
data BinaryOperator
  = Add               -- +
  | Subtract          -- -
  | Multiply          -- *
  | Divide            -- /
  | FloorDivide       -- //
  | Modulo            -- %
  | Power             -- **
  | EqualTo           -- ==
  | NotEqualTo        -- !=
  | LessThan          -- <
  | LessThanOrEqualTo -- <=
  | GreaterThan       -- >
  | GreaterThanOrEqualTo -- >=
  | And               -- and
  | Or                -- or
  | BitwiseAnd        -- &
  | BitwiseOr         -- |
  | BitwiseXor        -- ^
  | ShiftLeft         -- <<
  | ShiftRight        -- >>
  | Is                -- is
  | IsNot             -- is not
  | In                -- in
  | NotIn             -- not in
  deriving (Show, Eq)

-- | Simplified Python types (for type hints)
data PyType
  = PyTyAny
  | PyTyNone
  | PyTyBool
  | PyTyInt
  | PyTyFloat
  | PyTyStr
  | PyTyBytes
  | PyTyList PyType
  | PyTyDict PyType PyType
  | PyTyTuple [PyType]
  | PyTyCallable [PyType] PyType
  | PyTyOptional PyType
  | PyTyUnion [PyType]
  | PyTyVar Text
  | PyTyGeneric Text [PyType]
  deriving (Show, Eq)

-- | Transform all nodes in the AST (bottom-up)
everywhereOnPy :: (Py -> Py) -> Py -> Py
everywhereOnPy f = go
  where
  go :: Py -> Py
  go (PyUnary op e) = f $ PyUnary op (go e)
  go (PyBinary op e1 e2) = f $ PyBinary op (go e1) (go e2)
  go (PyFunctionDef t ss name args e) = f $ PyFunctionDef t ss name args (go e)
  go (PyVarBind x e) = f $ PyVarBind x (go e)
  go (PyLambda args e) = f $ PyLambda args (go e)
  go (PyApp fn args) = f $ PyApp (go fn) (map go args)
  go (PyMethodCall obj method args) = f $ PyMethodCall (go obj) method (map go args)
  go (PyAttr obj attr) = f $ PyAttr (go obj) attr
  go (PyBlock es) = f $ PyBlock (map go es)
  go (PyReturn e) = f $ PyReturn (go e)
  go (PyTuple es) = f $ PyTuple (map go es)
  go (PyList es) = f $ PyList (map go es)
  go (PyDict pairs) = f $ PyDict (map (\(k, v) -> (go k, go v)) pairs)
  go (PyRecord pairs) = f $ PyRecord (map (second go) pairs)
  go (PyDictUpdate e pairs) = f $ PyDictUpdate (go e) (map (second go) pairs)
  go (PySubscript obj key) = f $ PySubscript (go obj) (go key)
  go (PyIfExp cond t e) = f $ PyIfExp (go cond) (go t) (go e)
  go (PyIf branches els) = f $ PyIf (map (\(c, b) -> (go c, go b)) branches) (fmap go els)
  go (PyMatch e cases) = f $ PyMatch (go e) (map (\(p, g, b) -> (p, fmap go g, go b)) cases)
  go (PyRaise e) = f $ PyRaise (go e)
  go (PyClass name base body) = f $ PyClass name base (map go body)
  go (PyDecorated dec e) = f $ PyDecorated dec (go e)
  go other = f other

-- | Transform all nodes in the AST (top-down)
everywhereOnPyTopDown :: (Py -> Py) -> Py -> Py
everywhereOnPyTopDown f = runIdentity . everywhereOnPyTopDownM (Identity . f)

everywhereOnPyTopDownM :: forall m. (Monad m) => (Py -> m Py) -> Py -> m Py
everywhereOnPyTopDownM f = f >=> go
  where
  f' = f >=> go

  go (PyUnary op e) = PyUnary op <$> f' e
  go (PyBinary op e1 e2) = PyBinary op <$> f' e1 <*> f' e2
  go (PyFunctionDef t ss name args e) = PyFunctionDef t ss name args <$> f' e
  go (PyVarBind x e) = PyVarBind x <$> f' e
  go (PyLambda args e) = PyLambda args <$> f' e
  go (PyApp fn args) = PyApp <$> f' fn <*> traverse f' args
  go (PyMethodCall obj method args) = PyMethodCall <$> f' obj <*> pure method <*> traverse f' args
  go (PyAttr obj attr) = PyAttr <$> f' obj <*> pure attr
  go (PyBlock es) = PyBlock <$> traverse f' es
  go (PyReturn e) = PyReturn <$> f' e
  go (PyTuple es) = PyTuple <$> traverse f' es
  go (PyList es) = PyList <$> traverse f' es
  go (PyDict pairs) = PyDict <$> traverse (\(k, v) -> (,) <$> f' k <*> f' v) pairs
  go (PyRecord pairs) = PyRecord <$> traverse (\(k, v) -> (k,) <$> f' v) pairs
  go (PyDictUpdate e pairs) = PyDictUpdate <$> f' e <*> traverse (\(k, v) -> (k,) <$> f' v) pairs
  go (PySubscript obj key) = PySubscript <$> f' obj <*> f' key
  go (PyIfExp cond t e) = PyIfExp <$> f' cond <*> f' t <*> f' e
  go (PyIf branches els) = PyIf <$> traverse (\(c, b) -> (,) <$> f' c <*> f' b) branches <*> traverse f' els
  go (PyMatch e cases) = PyMatch <$> f' e <*> traverse (\(p, g, b) -> (p,,) <$> traverse f' g <*> f' b) cases
  go (PyRaise e) = PyRaise <$> f' e
  go (PyClass name base body) = PyClass name base <$> traverse f' body
  go (PyDecorated dec e) = PyDecorated dec <$> f' e
  go other = pure other

-- | Collect information from all nodes in the AST
everything :: forall r. (r -> r -> r) -> (Py -> r) -> Py -> r
everything (<>.) f = go
  where
  go :: Py -> r
  go e0@(PyUnary _ e) = f e0 <>. go e
  go e0@(PyBinary _ e1 e2) = f e0 <>. go e1 <>. go e2
  go e0@(PyFunctionDef _ _ _ _ e) = f e0 <>. go e
  go e0@(PyVarBind _ e) = f e0 <>. go e
  go e0@(PyLambda _ e) = f e0 <>. go e
  go e0@(PyApp fn args) = foldl (<>.) (f e0 <>. go fn) (map go args)
  go e0@(PyMethodCall obj _ args) = foldl (<>.) (f e0 <>. go obj) (map go args)
  go e0@(PyAttr obj _) = f e0 <>. go obj
  go e0@(PyBlock es) = foldl (<>.) (f e0) (map go es)
  go e0@(PyReturn e) = f e0 <>. go e
  go e0@(PyTuple es) = foldl (<>.) (f e0) (map go es)
  go e0@(PyList es) = foldl (<>.) (f e0) (map go es)
  go e0@(PyDict pairs) = foldl (<>.) (f e0) (map (\(k, v) -> go k <>. go v) pairs)
  go e0@(PyRecord pairs) = foldl (<>.) (f e0) (map (go . snd) pairs)
  go e0@(PyDictUpdate e pairs) = foldl (<>.) (f e0 <>. go e) (map (go . snd) pairs)
  go e0@(PySubscript obj key) = f e0 <>. go obj <>. go key
  go e0@(PyIfExp cond t e) = f e0 <>. go cond <>. go t <>. go e
  go e0@(PyIf branches els) = foldl (<>.) (f e0) (map (\(c, b) -> go c <>. go b) branches ++ maybe [] (pure . go) els)
  go e0@(PyMatch e cases) = foldl (<>.) (f e0 <>. go e) (map (\(_, g, b) -> maybe (f PyPass) go g <>. go b) cases)
  go e0@(PyRaise e) = f e0 <>. go e
  go e0@(PyClass _ _ body) = foldl (<>.) (f e0) (map go body)
  go e0@(PyDecorated _ e) = f e0 <>. go e
  go other = f other
