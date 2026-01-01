-- | Python abstract syntax types
module PureScript.Backend.Python.Syntax where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Data.Tuple (Tuple)

-- | Python identifier
newtype PyIdent = PyIdent String

derive instance Newtype PyIdent _
derive newtype instance Eq PyIdent
derive newtype instance Ord PyIdent
derive newtype instance Show PyIdent

-- | Python expression
data PyExpr
  = PyVar PyIdent
  | PyLitInt Int
  | PyLitNumber Number
  | PyLitString String
  | PyLitBool Boolean
  | PyLitNone
  | PyLitArray (Array PyExpr)
  | PyLitObject (Array (Tuple String PyExpr))
  | PyLambda (Array PyIdent) PyExpr
  | PyApp PyExpr (Array PyExpr)
  | PyAccess PyExpr String
  | PyIndex PyExpr PyExpr
  | PyBinOp String PyExpr PyExpr
  | PyUnaryOp String PyExpr
  | PyTernary PyExpr PyExpr PyExpr  -- cond ? then : else
  | PyTuple (Array PyExpr)
  | PyWalrus PyIdent PyExpr  -- := assignment expression
  | PyCall PyExpr (Array PyExpr)  -- function call

derive instance Eq PyExpr

-- | Python statement
data PyStmt
  = PyAssign PyIdent PyExpr
  | PyExprStmt PyExpr
  | PyReturn PyExpr
  | PyIf PyExpr (Array PyStmt) (Maybe (Array PyStmt))
  | PyWhile PyExpr (Array PyStmt)
  | PyFor PyIdent PyExpr (Array PyStmt)
  | PyDef PyIdent (Array PyIdent) (Array PyStmt)
  | PyClass PyIdent (Maybe PyIdent) (Array PyStmt)
  | PyImport String
  | PyFromImport String (Array String)
  | PyPass
  | PyComment String

derive instance Eq PyStmt

-- | Python module
type PyModule =
  { name :: String
  , imports :: Array PyStmt
  , body :: Array PyStmt
  }

-- | Create a simple variable reference
pyVar :: String -> PyExpr
pyVar = PyVar <<< PyIdent

-- | Create an integer literal
pyInt :: Int -> PyExpr
pyInt = PyLitInt

-- | Create a string literal
pyString :: String -> PyExpr
pyString = PyLitString

-- | Create a boolean literal
pyBool :: Boolean -> PyExpr
pyBool = PyLitBool

-- | Create None
pyNone :: PyExpr
pyNone = PyLitNone

-- | Create a lambda expression
pyLambda :: Array String -> PyExpr -> PyExpr
pyLambda args body = PyLambda (map PyIdent args) body

-- | Create a function application
pyApp :: PyExpr -> Array PyExpr -> PyExpr
pyApp = PyApp

-- | Create an assignment statement
pyAssign :: String -> PyExpr -> PyStmt
pyAssign name expr = PyAssign (PyIdent name) expr

-- | Create a constructor tuple (tag, fields...)
pyConstructor :: String -> Array PyExpr -> PyExpr
pyConstructor tag fields = PyTuple (Array.cons (pyString tag) fields)
