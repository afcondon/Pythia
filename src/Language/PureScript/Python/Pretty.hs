{-# LANGUAGE OverloadedStrings #-}

-- |
-- Pretty printer for Python AST
--
module Language.PureScript.Python.Pretty
  ( prettyPrintPy
  , prettyPrintPyModule
  ) where

import Prelude

import Control.Monad.State
import Data.Text (Text)
import qualified Data.Text as T

import Language.PureScript.PSString (PSString, decodeString)
import Language.PureScript.Python.CodeGen.AST

-- | Printer state tracks current indentation level
data PrinterState = PrinterState
  { indent :: Int
  , indentSize :: Int
  }

defaultState :: PrinterState
defaultState = PrinterState 0 4

-- | Increase indentation for nested block
withIndent :: State PrinterState Text -> State PrinterState Text
withIndent action = do
  modify $ \st -> st { indent = indent st + indentSize st }
  result <- action
  modify $ \st -> st { indent = indent st - indentSize st }
  return result

-- | Get current indentation string
currentIndent :: State PrinterState Text
currentIndent = do
  n <- gets indent
  return $ T.replicate n " "

-- | Pretty print a list of Python statements as a module
prettyPrintPyModule :: [Py] -> Text
prettyPrintPyModule stmts = evalState (prettyStatements stmts) defaultState

-- | Pretty print a single expression
prettyPrintPy :: Py -> Text
prettyPrintPy expr = evalState (prettyExpr expr) defaultState

-- | Print multiple statements separated by newlines
prettyStatements :: [Py] -> State PrinterState Text
prettyStatements stmts = do
  stmts' <- mapM prettyStatement stmts
  return $ T.intercalate "\n" stmts'

-- | Print a statement (with optional newline handling)
prettyStatement :: Py -> State PrinterState Text
prettyStatement stmt = do
  ind <- currentIndent
  case stmt of
    PyFunctionDef ty _ss name args body -> do
      let tyHint = maybe "" (\t -> " -> " <> prettyType t) ty
      let argsStr = T.intercalate ", " args
      bodyStr <- withIndent $ prettyBlock body
      return $ ind <> "def " <> name <> "(" <> argsStr <> ")" <> tyHint <> ":\n" <> bodyStr

    PyClass name base body -> do
      let baseStr = maybe "" (\b -> "(" <> b <> ")") base
      bodyStr <- if null body
                   then return $ ind <> "    pass"
                   else withIndent $ prettyStatements body
      return $ ind <> "class " <> name <> baseStr <> ":\n" <> bodyStr

    PyVarBind var val -> do
      valStr <- prettyExpr val
      return $ ind <> var <> " = " <> valStr

    PyIf branches mElse -> do
      let printBranch isFirst (cond, body) = do
            condStr <- prettyExpr cond
            bodyStr <- withIndent $ prettyBlock body
            let keyword = if isFirst then "if " else "elif "
            return $ ind <> keyword <> condStr <> ":\n" <> bodyStr
      branchStrs <- zipWithM printBranch (True : repeat False) branches
      elseStr <- case mElse of
        Nothing -> return ""
        Just els -> do
          elsBody <- withIndent $ prettyBlock els
          return $ "\n" <> ind <> "else:\n" <> elsBody
      return $ T.intercalate "\n" branchStrs <> elseStr

    PyMatch expr cases -> do
      exprStr <- prettyExpr expr
      casesStrs <- do
        modify $ \st -> st { indent = indent st + indentSize st }
        result <- mapM printCase cases
        modify $ \st -> st { indent = indent st - indentSize st }
        return result
      return $ ind <> "match " <> exprStr <> ":\n" <> T.intercalate "\n" casesStrs
      where
        printCase :: (PyPattern, Maybe Py, Py) -> State PrinterState Text
        printCase (pat, grd, body) = do
          ind' <- currentIndent
          let guardStr = maybe "" (\g -> " if " <> evalState (prettyExpr g) defaultState) grd
          bodyStr <- withIndent $ prettyBlock body
          return $ ind' <> "case " <> prettyPattern pat <> guardStr <> ":\n" <> bodyStr

    PyReturn e -> do
      eStr <- prettyExpr e
      return $ ind <> "return " <> eStr

    PyFromImport modName names -> do
      return $ ind <> "from " <> modName <> " import " <> T.intercalate ", " names

    PyImport modName -> do
      return $ ind <> "import " <> modName

    PyRaise e -> do
      eStr <- prettyExpr e
      return $ ind <> "raise " <> eStr

    PyPass -> return $ ind <> "pass"

    PyComment txt -> return $ ind <> "# " <> txt

    PyDecorated dec inner -> do
      innerStr <- prettyStatement inner
      return $ ind <> "@" <> dec <> "\n" <> innerStr

    PyBlock stmts -> prettyStatements stmts

    -- Expression statements
    other -> do
      exprStr <- prettyExpr other
      return $ ind <> exprStr

-- | Print a block body (indented statements)
prettyBlock :: Py -> State PrinterState Text
prettyBlock (PyBlock []) = do
  ind <- currentIndent
  return $ ind <> "pass"
prettyBlock (PyBlock stmts) = prettyStatements stmts
prettyBlock stmt = prettyStatement stmt

-- | Print an expression
prettyExpr :: Py -> State PrinterState Text
prettyExpr = \case
  PyNumericLiteral n -> return $ either (T.pack . show) (T.pack . show) n

  PyStringLiteral s -> return $ prettyString s

  PyBoolLiteral True -> return "True"
  PyBoolLiteral False -> return "False"

  PyNone -> return "None"

  PyVar name -> return name

  PyUnary op e -> do
    eStr <- prettyExpr e
    return $ prettyUnaryOp op <> "(" <> eStr <> ")"

  PyBinary op e1 e2 -> do
    e1Str <- prettyExpr e1
    e2Str <- prettyExpr e2
    return $ "(" <> e1Str <> " " <> prettyBinaryOp op <> " " <> e2Str <> ")"

  PyLambda [] body -> do
    bodyStr <- prettyExpr body
    return $ "(lambda: " <> bodyStr <> ")"

  PyLambda args body -> do
    bodyStr <- prettyExpr body
    return $ "(lambda " <> T.intercalate ", " args <> ": " <> bodyStr <> ")"

  PyApp fn [] -> do
    fnStr <- prettyExpr fn
    return $ fnStr <> "()"

  PyApp fn args -> do
    fnStr <- prettyExpr fn
    argsStr <- mapM prettyExpr args
    return $ fnStr <> "(" <> T.intercalate ", " argsStr <> ")"

  PyMethodCall obj method args -> do
    objStr <- prettyExpr obj
    argsStr <- mapM prettyExpr args
    return $ objStr <> "." <> method <> "(" <> T.intercalate ", " argsStr <> ")"

  PyAttr obj attr -> do
    objStr <- prettyExpr obj
    return $ objStr <> "." <> attr

  PyTuple [] -> return "()"
  PyTuple [e] -> do
    eStr <- prettyExpr e
    return $ "(" <> eStr <> ",)"
  PyTuple es -> do
    esStr <- mapM prettyExpr es
    return $ "(" <> T.intercalate ", " esStr <> ")"

  PyList es -> do
    esStr <- mapM prettyExpr es
    return $ "[" <> T.intercalate ", " esStr <> "]"

  PyDict [] -> return "{}"
  PyDict pairs -> do
    pairsStr <- mapM (\(k, v) -> do
      kStr <- prettyExpr k
      vStr <- prettyExpr v
      return $ kStr <> ": " <> vStr) pairs
    return $ "{" <> T.intercalate ", " pairsStr <> "}"

  PyRecord [] -> return "{}"
  PyRecord pairs -> do
    pairsStr <- mapM (\(k, v) -> do
      vStr <- prettyExpr v
      return $ "\"" <> k <> "\": " <> vStr) pairs
    return $ "{" <> T.intercalate ", " pairsStr <> "}"

  PyDictUpdate base [] -> prettyExpr base
  PyDictUpdate base pairs -> do
    baseStr <- prettyExpr base
    pairsStr <- mapM (\(k, v) -> do
      vStr <- prettyExpr v
      return $ "\"" <> k <> "\": " <> vStr) pairs
    return $ "{**" <> baseStr <> ", " <> T.intercalate ", " pairsStr <> "}"

  PySubscript obj key -> do
    objStr <- prettyExpr obj
    keyStr <- prettyExpr key
    return $ objStr <> "[" <> keyStr <> "]"

  PyIfExp cond thenE elseE -> do
    condStr <- prettyExpr cond
    thenStr <- prettyExpr thenE
    elseStr <- prettyExpr elseE
    return $ "(" <> thenStr <> " if " <> condStr <> " else " <> elseStr <> ")"

  PyBlock [e] -> prettyExpr e
  PyBlock _ -> return "..."  -- Blocks as expressions shouldn't happen

  PyReturn e -> do
    eStr <- prettyExpr e
    return $ "return " <> eStr

  PyRaise e -> do
    eStr <- prettyExpr e
    return $ "raise " <> eStr

  PyPass -> return "pass"

  PyComment txt -> return $ "# " <> txt

  _ -> return "..."  -- Fallback for statements used as expressions

-- | Pretty print a pattern
prettyPattern :: PyPattern -> Text
prettyPattern = \case
  PyPatternVar name -> name
  PyPatternWildcard -> "_"
  PyPatternLiteral lit -> evalState (prettyExpr lit) defaultState
  PyPatternTuple pats -> "(" <> T.intercalate ", " (map prettyPattern pats) <> ")"
  PyPatternList pats -> "[" <> T.intercalate ", " (map prettyPattern pats) <> "]"
  PyPatternCtor name [] -> name <> "()"
  PyPatternCtor name pats -> name <> "(" <> T.intercalate ", " (map prettyPattern pats) <> ")"
  PyPatternAs pat name -> prettyPattern pat <> " as " <> name
  PyPatternOr pats -> T.intercalate " | " (map prettyPattern pats)

-- | Pretty print a unary operator
prettyUnaryOp :: UnaryOperator -> Text
prettyUnaryOp = \case
  Negate -> "-"
  Not -> "not "
  BitwiseNot -> "~"
  Positive -> "+"

-- | Pretty print a binary operator
prettyBinaryOp :: BinaryOperator -> Text
prettyBinaryOp = \case
  Add -> "+"
  Subtract -> "-"
  Multiply -> "*"
  Divide -> "/"
  FloorDivide -> "//"
  Modulo -> "%"
  Power -> "**"
  EqualTo -> "=="
  NotEqualTo -> "!="
  LessThan -> "<"
  LessThanOrEqualTo -> "<="
  GreaterThan -> ">"
  GreaterThanOrEqualTo -> ">="
  And -> "and"
  Or -> "or"
  BitwiseAnd -> "&"
  BitwiseOr -> "|"
  BitwiseXor -> "^"
  ShiftLeft -> "<<"
  ShiftRight -> ">>"
  Is -> "is"
  IsNot -> "is not"
  In -> "in"
  NotIn -> "not in"

-- | Pretty print a type annotation
prettyType :: PyType -> Text
prettyType = \case
  PyTyAny -> "Any"
  PyTyNone -> "None"
  PyTyBool -> "bool"
  PyTyInt -> "int"
  PyTyFloat -> "float"
  PyTyStr -> "str"
  PyTyBytes -> "bytes"
  PyTyList t -> "list[" <> prettyType t <> "]"
  PyTyDict k v -> "dict[" <> prettyType k <> ", " <> prettyType v <> "]"
  PyTyTuple ts -> "tuple[" <> T.intercalate ", " (map prettyType ts) <> "]"
  PyTyCallable args ret -> "Callable[[" <> T.intercalate ", " (map prettyType args) <> "], " <> prettyType ret <> "]"
  PyTyOptional t -> prettyType t <> " | None"
  PyTyUnion ts -> T.intercalate " | " (map prettyType ts)
  PyTyVar name -> name
  PyTyGeneric name args -> name <> "[" <> T.intercalate ", " (map prettyType args) <> "]"

-- | Pretty print a PSString to a Python string literal
prettyString :: PSString -> Text
prettyString s = case decodeString s of
  Just str -> "\"" <> escapeString str <> "\""
  Nothing -> "b\"" <> escapeString (T.pack "...") <> "\""  -- Fallback for non-UTF8

-- | Escape special characters in a string
escapeString :: Text -> Text
escapeString = T.concatMap escapeChar
  where
    escapeChar '\\' = "\\\\"
    escapeChar '"' = "\\\""
    escapeChar '\n' = "\\n"
    escapeChar '\r' = "\\r"
    escapeChar '\t' = "\\t"
    escapeChar c = T.singleton c
