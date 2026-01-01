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

import Language.PureScript.Python.CodeGen.Common (pyModuleNameBase)

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

          -- Generate Python code directly (simplified approach)
          let pyCode = generateModulePy cfModule

          -- Add module header
          let header = generateHeader moduleName
              fullCode = header <> pyCode

          -- Write output file
          liftIO $ do
            createDirectoryIfMissing True (takeDirectory outFile)
            TIO.writeFile outFile fullCode

          return pyModName

-- | Generate Python code for a module (simplified direct translation)
generateModulePy :: CoreFn.Module CoreFn.Ann -> T.Text
generateModulePy cfModule = T.unlines $ map generateBinding (CoreFn.moduleDecls cfModule)
  where
    generateBinding :: CoreFn.Bind CoreFn.Ann -> T.Text
    generateBinding (CoreFn.NonRec _ ident expr) =
      identName ident <> " = " <> generateExpr expr
    generateBinding (CoreFn.Rec bindings) =
      T.unlines [identName ident <> " = " <> generateExpr expr | ((_, ident), expr) <- bindings]

    identName :: P.Ident -> T.Text
    identName = P.runIdent

    generateExpr :: CoreFn.Expr CoreFn.Ann -> T.Text
    generateExpr = \case
      CoreFn.Literal _ lit -> generateLiteral lit
      CoreFn.Var _ qi -> generateQualifiedIdent qi
      CoreFn.Abs _ arg body ->
        "(lambda " <> identName arg <> ": " <> generateExpr body <> ")"
      CoreFn.App _ fn arg ->
        "(" <> generateExpr fn <> ")(" <> generateExpr arg <> ")"
      CoreFn.Let _ binds body ->
        "(lambda: (" <> T.intercalate ", " (map generateLetBind binds) <> ", " <> generateExpr body <> ")[-1])()"
      CoreFn.Case _ exprs alts ->
        -- Simplified: just generate first alternative for now
        case alts of
          [] -> "None  # empty case"
          (alt:_) -> generateCaseAlt exprs alt
      CoreFn.Accessor _ field expr ->
        generateExpr expr <> "[\"" <> psToText field <> "\"]"
      CoreFn.ObjectUpdate _ expr _ updates ->
        "{**" <> generateExpr expr <> ", " <>
        T.intercalate ", " ["\"" <> psToText k <> "\": " <> generateExpr v | (k, v) <- updates] <> "}"
      CoreFn.Constructor _ _ (P.ProperName ctor) fields ->
        if null fields
          then "(\"" <> ctor <> "\",)"
          else "(lambda " <> T.intercalate ": lambda " (map identName fields) <>
               ": (\"" <> ctor <> "\", " <> T.intercalate ", " (map identName fields) <> "))"

    generateLetBind :: CoreFn.Bind CoreFn.Ann -> T.Text
    generateLetBind (CoreFn.NonRec _ ident expr) =
      "(" <> identName ident <> " := " <> generateExpr expr <> ")"
    generateLetBind (CoreFn.Rec _) = "None  # recursive let"

    generateCaseAlt :: [CoreFn.Expr CoreFn.Ann] -> CoreFn.CaseAlternative CoreFn.Ann -> T.Text
    generateCaseAlt _ (CoreFn.CaseAlternative _ (Right body)) = generateExpr body
    generateCaseAlt _ (CoreFn.CaseAlternative _ (Left _)) = "None  # guarded case"

    generateLiteral :: CoreFn.Literal (CoreFn.Expr CoreFn.Ann) -> T.Text
    generateLiteral = \case
      CoreFn.NumericLiteral (Left n) -> T.pack (show n)
      CoreFn.NumericLiteral (Right n) -> T.pack (show n)
      CoreFn.StringLiteral s ->
        case decodeString s of
          Just str -> "\"" <> escapeString str <> "\""
          Nothing -> "\"<invalid string>\""
      CoreFn.CharLiteral c -> "\"" <> T.singleton c <> "\""
      CoreFn.BooleanLiteral True -> "True"
      CoreFn.BooleanLiteral False -> "False"
      CoreFn.ArrayLiteral exprs -> "[" <> T.intercalate ", " (map generateExpr exprs) <> "]"
      CoreFn.ObjectLiteral fields ->
        "{" <> T.intercalate ", " ["\"" <> psToText k <> "\": " <> generateExpr v | (k, v) <- fields] <> "}"

    psToText :: PSString -> T.Text
    psToText s = case decodeString s of
      Just str -> str
      Nothing -> "<invalid>"

    generateQualifiedIdent :: P.Qualified P.Ident -> T.Text
    generateQualifiedIdent (P.Qualified qb ident) =
      case qb of
        P.ByModuleName (P.ModuleName "Effect.Console")
          | P.runIdent ident == "log" -> "effect_console_log"
        P.ByModuleName (P.ModuleName "Prim")
          | P.runIdent ident == "undefined" -> "None"
        P.ByModuleName mn -> pyModuleNameBase mn <> "." <> identName ident
        P.BySourcePos _ -> identName ident

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
generateHeader :: P.ModuleName -> T.Text
generateHeader (P.ModuleName name) = T.unlines
  [ "# Generated by purepy from PureScript module: " <> name
  , "# Do not edit this file directly"
  , ""
  , "from purepy_runtime import *"
  , ""
  ]

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

-- | Python runtime support code
runtimeCode :: T.Text
runtimeCode = T.unlines
  [ "# PureScript Python Runtime"
  , "# Generated by purepy"
  , ""
  , "# Unit type"
  , "unit = None"
  , ""
  , "# Effect.Console.log"
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
