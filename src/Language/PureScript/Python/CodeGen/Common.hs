{-# LANGUAGE OverloadedStrings #-}

-- |
-- Naming and identifier utilities for the Python backend.
--
-- PureScript module names keep their case and join segments with
-- underscores (@Data.Array@ -> @Data_Array@). Identifiers keep their
-- camelCase; primes become U+02B9 MODIFIER LETTER PRIME (category Lm,
-- legal in Python identifiers, so @go'@ stays visually a prime without
-- risking collision with a literal @go_prime@), and Python reserved
-- words get an underscore suffix.
--
module Language.PureScript.Python.CodeGen.Common
  ( pyModuleName
  , pyFileName
  , pyForeignModuleName
  , pyForeignFileName
  , toPythonIdent
  , identToPyName
  , runIdent'
  , psStringToText
  , escapeStringPy
  , escapeCharPy
  , nameIsPythonReserved
  ) where

import Prelude
import Data.Char (isAlpha, isDigit, ord)
import Data.Text (Text, uncons, singleton, pack)
import qualified Data.Text as T
import Data.Word (Word16)
import Language.PureScript.Names
    ( ModuleName(..), Ident (InternalIdent), runIdent, InternalIdentData (RuntimeLazyFactory, Lazy) )
import Language.PureScript.PSString (PSString, decodeStringEither)
import Numeric (showHex)

-- | Convert a ModuleName to a Python module name
-- e.g., Data.Array -> Data_Array. PS module segments are ProperNames
-- (uppercase-start), so they cannot collide with the underscore-prefixed
-- runtime module or with lowercase stdlib modules.
pyModuleName :: ModuleName -> Text
pyModuleName (ModuleName name) = T.intercalate "_" (T.splitOn "." name)

-- | Output filename for a PureScript module
pyFileName :: ModuleName -> FilePath
pyFileName mn = T.unpack (pyModuleName mn) <> ".py"

-- | Module name of the foreign (FFI) companion module
pyForeignModuleName :: ModuleName -> Text
pyForeignModuleName mn = pyModuleName mn <> "_foreign"

-- | Filename of the foreign (FFI) companion file for a module
pyForeignFileName :: ModuleName -> FilePath
pyForeignFileName mn = T.unpack (pyForeignModuleName mn) <> ".py"

-- | Convert a PSString to escaped content for a double-quoted Python
-- string literal. Lone surrogates become \uXXXX escapes (legal in Python
-- strings); full codepoints outside the escape set pass through raw
-- (the output file is UTF-8).
psStringToText :: PSString -> Text
psStringToText a = foldMap escapeChar (decodeStringEither a)
  where
    escapeChar :: Either Word16 Char -> Text
    escapeChar (Left w) = "\\u" <> hex 4 w
    escapeChar (Right c) = replaceBasicEscape c

replaceBasicEscape :: Char -> Text
replaceBasicEscape '\b' = "\\b"
replaceBasicEscape '\t' = "\\t"
replaceBasicEscape '\n' = "\\n"
replaceBasicEscape '\f' = "\\f"
replaceBasicEscape '\r' = "\\r"
replaceBasicEscape '"'  = "\\\""
replaceBasicEscape '\\' = "\\\\"
replaceBasicEscape c
  | ord c < 0x20 = "\\u" <> hex 4 c
  | otherwise = singleton c

-- | Escape plain Text for embedding in a double-quoted Python string literal
escapeStringPy :: Text -> Text
escapeStringPy = T.concatMap replaceBasicEscape

-- | Escape a character for a Python "char" (a 1-character double-quoted
-- string - Python has no char type, matching the JS representation)
escapeCharPy :: Char -> Text
escapeCharPy = replaceBasicEscape

hex :: (Enum a) => Int -> a -> Text
hex width c =
  let hs = showHex (fromEnum c) "" in
  pack (replicate (width - length hs) '0' <> hs)

-- | Convert a PureScript identifier to a valid Python identifier
toPythonIdent :: Text -> Text
toPythonIdent v = case uncons v of
  Just (h, t) ->
    replaceFirst h <> T.concatMap replaceChar t
  Nothing -> v
  where
    replaceChar '.' = "_"
    replaceChar '$' = "_dollar_"
    replaceChar '\'' = "\x02B9"   -- modifier letter prime (Lm)
    replaceChar '-' = "_"
    replaceChar c | isValidPythonChar c = singleton c
    replaceChar c = "_u" <> hex 4 c

    replaceFirst x
      | isAlpha x || x == '_' = singleton x
      | otherwise = "_" <> replaceChar x

    isValidPythonChar c = isAlpha c || isDigit c || c == '_' || c == '\x02B9'

-- | Convert an Ident to a Python name, escaping reserved words
identToPyName :: Ident -> Text
identToPyName ident =
  let name = toPythonIdent (runIdent' ident)
  in if nameIsPythonReserved name
     then name <> "_"
     else name

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

-- | Python reserved words (keywords; soft keywords like @match@/@case@
-- remain legal identifiers and are not escaped)
pythonReserved :: [Text]
pythonReserved =
  [ "False", "None", "True"
  , "and", "as", "assert", "async", "await"
  , "break", "class", "continue", "def", "del"
  , "elif", "else", "except", "finally", "for"
  , "from", "global", "if", "import", "in"
  , "is", "lambda", "nonlocal", "not", "or"
  , "pass", "raise", "return", "try", "while"
  , "with", "yield"
  ]
