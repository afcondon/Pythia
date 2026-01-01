-- |
-- Common code generation utility functions
--
module Language.PureScript.Python.CodeGen.Common
( pyModuleName
, pyModuleNameBase
, ModuleType(..)
, toSnakeCase
, toPythonIdent
, identToVar
, identToPyName
, nameIsPythonReserved
, freshNamePy
, freshNamePy'
, runIdent'
, psStringToText
) where

import Prelude
import Data.Char
    ( isDigit, isAlpha, isUpper, toLower )
import Data.Text (Text, uncons, cons, singleton, pack)
import qualified Data.Text as T
import Data.Word (Word16)
import Language.PureScript.Names
    ( ModuleName(..), Ident (InternalIdent), runIdent, InternalIdentData (RuntimeLazyFactory, Lazy) )
import Language.PureScript.PSString
    ( PSString(..), decodeStringEither )
import Numeric ( showHex )
import Control.Monad.Supply.Class (MonadSupply (fresh))

-- | Module type for Python output
data ModuleType = ForeignModule | PureScriptModule
  deriving (Show, Eq)

-- | Convert PSString to Text, escaping non-printable characters
psStringToText :: PSString -> Text
psStringToText a = foldMap escapeChar (decodeStringEither a)
  where
    escapeChar :: Either Word16 Char -> Text
    escapeChar (Left w) = "\\x" <> hex 4 w
    escapeChar (Right c) = replaceBasicEscape c

replaceBasicEscape :: Char -> Text
replaceBasicEscape '\b' = "\\b"
replaceBasicEscape '\t' = "\\t"
replaceBasicEscape '\n' = "\\n"
replaceBasicEscape '\f' = "\\f"
replaceBasicEscape '\r' = "\\r"
replaceBasicEscape '"'  = "\\\""
replaceBasicEscape '\\' = "\\\\"
replaceBasicEscape c = singleton c

hex :: (Enum a) => Int -> a -> Text
hex width c =
  let hs = showHex (fromEnum c) "" in
  pack (replicate (width - length hs) '0' <> hs)

-- | Convert a ModuleName to a Python module name
-- e.g., Data.Array -> data_array
pyModuleName :: ModuleName -> ModuleType -> Text
pyModuleName mn moduleType = pyModuleNameBase mn <>
  case moduleType of
    ForeignModule -> "_foreign"
    PureScriptModule -> ""

-- | Base Python module name without suffix
pyModuleNameBase :: ModuleName -> Text
pyModuleNameBase (ModuleName name) =
  T.intercalate "_" (toSnakeCase <$> T.splitOn "." name)

-- | Convert a PascalCase or camelCase name to snake_case
toSnakeCase :: Text -> Text
toSnakeCase text = T.toLower $ case uncons text of
  Just (h, t) -> cons h (T.concatMap insertUnderscore t)
  Nothing -> text
  where
    insertUnderscore c
      | isUpper c = "_" <> singleton (toLower c)
      | otherwise = singleton c

-- | Convert a PureScript identifier to a valid Python identifier
toPythonIdent :: Text -> Text
toPythonIdent v = case uncons v of
  Just (h, t) ->
    replaceFirst h <> T.concatMap replaceChar t
  Nothing -> v
  where
    replaceChar '.' = "_"
    replaceChar '$' = "_dollar_"
    replaceChar '\'' = "_prime"
    replaceChar '-' = "_"
    replaceChar c | isValidPythonChar c = singleton c
    replaceChar c = "_u" <> hex 4 c

    replaceFirst x
      | isAlpha x || x == '_' = singleton x
      | otherwise = "_" <> replaceChar x

    isValidPythonChar c = isAlpha c || isDigit c || c == '_'

-- | Convert an Ident to a Python function/value name (snake_case)
-- Escapes Python reserved words by adding underscore suffix
identToPyName :: Ident -> Text
identToPyName ident =
  let name = toPythonIdent (runIdent' ident)
  in if nameIsPythonReserved name
     then name <> "_"
     else name

-- | Convert an Ident to a Python variable name
identToVar :: Ident -> Text
identToVar = identToPyName

-- | Get the raw text from an Ident, handling internal identifiers
runIdent' :: Ident -> Text
runIdent' = \case
  InternalIdent RuntimeLazyFactory -> "_runtime_lazy"
  InternalIdent (Lazy name) -> "_lazy_" <> name
  other -> runIdent other

-- |
-- Checks whether an identifier name is reserved in Python.
--
nameIsPythonReserved :: Text -> Bool
nameIsPythonReserved name = name `elem` pythonReserved

-- | Python reserved words (keywords and soft keywords)
pythonReserved :: [Text]
pythonReserved =
  [ "False", "None", "True"
  , "and", "as", "assert", "async", "await"
  , "break"
  , "class", "continue"
  , "def", "del"
  , "elif", "else", "except"
  , "finally", "for", "from"
  , "global"
  , "if", "import", "in", "is"
  , "lambda"
  , "match"  -- soft keyword in 3.10+
  , "nonlocal", "not"
  , "or"
  , "pass"
  , "raise", "return"
  , "try", "type"  -- soft keyword in 3.12+
  , "while", "with"
  , "yield"
  -- Common builtins to avoid shadowing
  , "print", "len", "range", "list", "dict", "set", "tuple"
  , "str", "int", "float", "bool", "bytes"
  , "object", "type", "super", "self"
  , "map", "filter", "zip", "enumerate"
  , "open", "input", "id", "hash", "iter", "next"
  , "abs", "all", "any", "min", "max", "sum"
  , "getattr", "setattr", "hasattr", "delattr"
  , "isinstance", "issubclass"
  , "callable", "repr", "format"
  ]

-- | Generate a fresh Python-safe variable name
freshNamePy' :: (MonadSupply m) => T.Text -> m T.Text
freshNamePy' base = fmap (((base <> "_") <>) . T.pack . show) fresh

-- | Generate a fresh Python-safe variable name with underscore prefix
freshNamePy :: (MonadSupply m) => m T.Text
freshNamePy = freshNamePy' "_v"
