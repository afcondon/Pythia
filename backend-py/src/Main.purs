-- | CLI for `backend-py` -- the optimizer-consumer lane for Pythia.
-- |
-- | Reads the CoreFn `purs` emitted, runs `purescript-backend-optimizer` over it,
-- | and writes one Python file per module into the output directory, alongside
-- | the `_purepy_runtime.py` and `<Module>_foreign.py` files that `purepy` (the
-- | oracle lane) produces. Nothing here writes a runtime or a foreign shim: the
-- | two lanes share one copy of each, so they cannot drift apart.
module Main where

import Prelude

import ArgParse.Basic (ArgParser)
import ArgParse.Basic as ArgParser
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldMap, for_)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import Effect.Ref as Ref
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.FS.Perms as Perms
import Node.Path (FilePath)
import Node.Path as Path
import Node.Process as Process
import PureScript.Backend.Optimizer.Codegen.Python (codegenModule, lazyIdentsOf, pyForeignModuleName, pyIdent, pyFileName, pyModuleAlias, pyModuleName, runtimeImport)
import PureScript.Backend.Optimizer.Codegen.Python.Builder (basicBuildMain)
import PureScript.Backend.Optimizer.Convert (BackendModule)
import PureScript.Backend.Optimizer.CoreFn (Ident(..), ModuleName(..), Qualified(..))
import PureScript.Backend.Optimizer.Reachability (pruneModule, reachableFromEntry)
import PureScript.Backend.Optimizer.Semantics.Foreign (coreForeignSemantics)

type BuildArgs =
  { coreFnDir :: FilePath
  , outputDir :: FilePath
  , mainModule :: String
  }

argParser :: ArgParser BuildArgs
argParser =
  ArgParser.fromRecord
    { coreFnDir:
        ArgParser.argument [ "--corefn-dir" ]
          "Path to input directory containing corefn.json files (default ./output)."
          # ArgParser.default (Path.concat [ ".", "output" ])
    , outputDir:
        ArgParser.argument [ "--output-dir" ]
          "Path to output directory for Python files (default ./output-py-opt)."
          # ArgParser.default (Path.concat [ ".", "output-py-opt" ])
    , mainModule:
        ArgParser.argument [ "--main" ]
          "Entry module whose `main :: Effect _` is run (default Main)."
          # ArgParser.default "Main"
    }
    <* ArgParser.flagHelp

main :: Effect Unit
main = do
  args <- Array.drop 2 <$> Process.argv
  case ArgParser.parseArgs "backend-py" "PureScript Python backend (optimizer IR)." argParser args of
    Left err -> Console.error (ArgParser.printArgError err)
    Right buildArgs -> launchAff_ (build buildArgs)

build :: BuildArgs -> Aff Unit
build args = do
  -- Accumulate every built module, then prune from the entry point. Pruning
  -- needs the whole reference graph, so nothing can be emitted as we go.
  modulesRef <- liftEffect (Ref.new [])
  basicBuildMain
    { resolveCoreFnDirectory: pure args.coreFnDir
    , resolveExternalDirectives: pure Map.empty
    , analyzeCustom: \_ _ -> Nothing
    , foreignSemantics: coreForeignSemantics
    , onCodegenBefore: mkdirp args.outputDir
    , onPrepareModule: \_ coreFnMod -> pure coreFnMod
    , onCodegenModule: \_ _ backendMod _ ->
        liftEffect (Ref.modify_ (_ <> [ backendMod ]) modulesRef)
    , onCodegenAfter: do
        modules <- liftEffect (Ref.read modulesRef)
        let
          entry = Qualified (Just (ModuleName args.mainModule)) (Ident "main")
          reachable = reachableFromEntry entry modules
          kept = Array.mapMaybe (keepModule reachable) modules
          -- Computed over the PRUNED modules, and over all of them, because the
          -- decision is per-definition while the reference can be anywhere.
          lazyIdents = foldMap lazyIdentsOf kept
        for_ kept \backendMod -> do
          let text = renderModule { lazyIdents } backendMod
          FS.writeTextFile UTF8 (Path.concat [ args.outputDir, pyFileName backendMod.name ]) text
        FS.writeTextFile UTF8 (Path.concat [ args.outputDir, "entrypoint.py" ])
          (renderEntrypoint lazyIdents args.mainModule)
    , traceIdents: Set.empty
    }

-- | Keep a module if entry reachability left it any binding, OR if any of its
-- | FOREIGN idents is reachable. The second case is not hypothetical: foreigns
-- | are not bindings, so they create no node in the reachability graph, and a
-- | module contributing only foreigns would otherwise be dropped out from under
-- | a live `_psmod_M.someForeign` reference.
keepModule :: Set (Qualified Ident) -> BackendModule -> Maybe BackendModule
keepModule reachable backendMod =
  case pruneModule reachable backendMod of
    Just pruned -> Just pruned
    Nothing
      | foreignReachable -> Just (backendMod { bindings = [] })
      | otherwise -> Nothing
  where
  foreignReachable = Array.any
    (\ident -> Set.member (Qualified (Just backendMod.name) ident) reachable)
    (Set.toUnfoldable backendMod.foreign)

renderModule :: { lazyIdents :: Set (Qualified Ident) } -> BackendModule -> String
renderModule { lazyIdents } backendMod =
  String.joinWith "\n" (header <> [ "" ] <> out.lines <> [ "" ])
  where
  out = codegenModule { currentModule: backendMod.name, lazyIdents, locals: Map.empty } backendMod

  header =
    [ "# Generated by backend-py (optimizer IR) from PureScript module: " <> unModuleName backendMod.name
    , "# Do not edit this file directly."
    , runtimeImport
    ]
      <> importLines
      <> foreignLines

  importLines =
    map (\mn -> "import " <> pyModuleName mn <> " as " <> pyModuleAlias mn)
      (Set.toUnfoldable out.used)

  -- Import every declared foreign, not just the referenced ones: another module
  -- may reach one through `_psmod_M.name`, which resolves in M's namespace.
  foreignLines =
    case Set.toUnfoldable backendMod.foreign :: Array Ident of
      [] -> []
      idents ->
        [ "from " <> pyForeignModuleName backendMod.name <> " import ("
            <> String.joinWith ", " (map pyIdent idents) <> ")"
        ]

-- | `main :: Effect Unit` is a thunk, so running the program is one extra call.
renderEntrypoint :: Set (Qualified Ident) -> String -> String
renderEntrypoint lazyIdents mainModule =
  String.joinWith "\n"
    [ "# Entry point generated by backend-py for module " <> mainModule
    , "import " <> pyModuleName mn <> " as _entry"
    , "_entry.main" <> forced <> "()"
    , ""
    ]
  where
  mn = ModuleName mainModule
  forced = if Set.member (Qualified (Just mn) (Ident "main")) lazyIdents then "()" else ""

unModuleName :: ModuleName -> String
unModuleName (ModuleName mn) = mn

mkdirp :: FilePath -> Aff Unit
mkdirp = flip FS.mkdir' { recursive: true, mode: Perms.mkPerms Perms.all Perms.all Perms.all }
