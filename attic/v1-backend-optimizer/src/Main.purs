module Main where

import Prelude

import Data.Argonaut.Parser (jsonParser)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.List as List
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Set as Set
import Data.String as String
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.Path as Path
import Node.Process as Process
import PureScript.Backend.Optimizer.Builder (buildModules)
import PureScript.Backend.Optimizer.CoreFn (Ann, Module(..))
import PureScript.Backend.Optimizer.CoreFn.Json (decodeModule)
import PureScript.Backend.Optimizer.CoreFn.Sort (sortModules)
import PureScript.Backend.Optimizer.Directives (parseDirectiveFile)
import PureScript.Backend.Optimizer.Directives.Defaults (defaultDirectives)
import PureScript.Backend.Python.Builder (generateRuntime, processModule)

-- | Main entry point
main :: Effect Unit
main = launchAff_ do
  args <- liftEffect Process.argv
  case Array.drop 2 args of
    [inputDir, outputDir] -> do
      Console.log $ "Compiling from " <> inputDir <> " to " <> outputDir
      compile { inputDir, outputDir }
    _ -> do
      Console.log "Usage: purescript-backend-python <input-dir> <output-dir>"
      Console.log "  input-dir:  Directory containing corefn.json files (usually 'output')"
      Console.log "  output-dir: Directory for Python output (usually 'output-py')"

-- | Compile options
type CompileOptions =
  { inputDir :: String
  , outputDir :: String
  }

-- | Main compilation pipeline
compile :: CompileOptions -> Aff Unit
compile opts = do
  -- Create output directory
  mkdirp opts.outputDir

  -- Find and read all corefn.json files
  modulePaths <- findCoreFnModules opts.inputDir
  Console.log $ "Found " <> show (Array.length modulePaths) <> " modules"

  -- Parse all CoreFn modules
  result <- loadModules modulePaths
  case result of
    Left errs -> do
      for_ errs \err -> Console.error err
      liftEffect $ Process.exit' 1
    Right modules -> do
      Console.log $ "Loaded " <> show (List.length modules) <> " modules"

      -- Sort modules by dependency order
      let sortedModules = sortModules modules

      Console.log "Running optimizer and generating Python..."

      -- Parse directives (defaults + Python-specific)
      let pythonDirectives = defaultDirectives <> """
        -- Python backend: prevent inlining of tailRec so we can recognize it
        Control.Monad.Rec.Class.tailRec never
        Control.Monad.Rec.Class.tailRecM never
        Control.Monad.Rec.Class.tailRec2 never
        Control.Monad.Rec.Class.tailRec3 never
        """
      let { directives } = parseDirectiveFile pythonDirectives

      -- Use the optimizer's buildModules
      let pyOpts = { outputDir: opts.outputDir, inputDir: opts.inputDir }
      sortedModules # buildModules
        { analyzeCustom: \_ _ -> Nothing  -- No custom analysis
        , directives                      -- Use our custom directives
        , foreignSemantics: Map.empty     -- No custom foreign semantics
        , onCodegenModule: \_ coreFnMod backendMod _ ->
            let Module { path } = coreFnMod
            in processModule pyOpts backendMod path
        , onPrepareModule: \_ mod -> pure mod
        , traceIdents: Set.empty
        }

      -- Generate runtime support
      generateRuntime opts.outputDir

      Console.log "Done!"

-- | Load all CoreFn modules from file paths
loadModules :: Array String -> Aff (Either (Array String) (List.List (Module Ann)))
loadModules paths = do
  results <- for paths \path -> do
    content <- FS.readTextFile UTF8 path
    case jsonParser content of
      Left err -> pure $ Left $ "JSON parse error in " <> path <> ": " <> err
      Right json -> case decodeModule json of
        Left decodeErr -> pure $ Left $ "CoreFn decode error in " <> path <> ": " <> show decodeErr
        Right mod -> pure $ Right mod
  let errs = Array.mapMaybe getLeft results
      mods = Array.mapMaybe getRight results
  if Array.null errs
    then pure $ Right $ List.fromFoldable mods
    else pure $ Left errs
  where
  getLeft (Left x) = Just x
  getLeft _ = Nothing
  getRight (Right x) = Just x
  getRight _ = Nothing

-- | Check if a file exists
fileExists :: String -> Aff Boolean
fileExists path = do
  result <- try (FS.stat path)
  pure $ case result of
    Left _ -> false
    Right _ -> true

-- | Find all corefn.json files in the input directory
findCoreFnModules :: String -> Aff (Array String)
findCoreFnModules inputDir = do
  entries <- FS.readdir inputDir
  let moduleDirs = Array.filter (not <<< isHidden) entries
      isHidden s = String.take 1 s == "."
  coreFnFiles <- for moduleDirs (findCoreFn inputDir)
  pure $ Array.catMaybes coreFnFiles
  where
  findCoreFn dir modName = do
    let path = Path.concat [dir, modName, "corefn.json"]
    exists <- fileExists path
    pure $ if exists then Just path else Nothing

-- | Create directory recursively
mkdirp :: String -> Aff Unit
mkdirp dir = do
  exists <- fileExists dir
  unless exists do
    FS.mkdir dir

-- | Helper for traversing with effects
for :: forall a b. Array a -> (a -> Aff b) -> Aff (Array b)
for arr f = do
  results <- pure []
  go arr results
  where
  go [] acc = pure acc
  go xs acc = case Array.uncons xs of
    Nothing -> pure acc
    Just { head, tail } -> do
      result <- f head
      go tail (Array.snoc acc result)
