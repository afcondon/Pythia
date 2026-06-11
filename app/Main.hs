{-# LANGUAGE OverloadedStrings #-}

module Main where

import Prelude
import System.Environment (getArgs)
import Language.PureScript.Python.Make (compile, CompileOptions(..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--help"] -> printHelp
    ["-h"] -> printHelp
    ["--version"] -> printVersion
    ["-v"] -> printVersion
    [] ->
      compile CompileOptions
        { inputDir = "output"
        , outputDir = "output-py"
        }
    [input] ->
      compile CompileOptions
        { inputDir = input
        , outputDir = "output-py"
        }
    [input, output] ->
      compile CompileOptions
        { inputDir = input
        , outputDir = output
        }
    _ -> do
      putStrLn "Usage: purepy [INPUT_DIR] [OUTPUT_DIR]"
      putStrLn "Run 'purepy --help' for more information."

printHelp :: IO ()
printHelp = do
  putStrLn "purepy - PureScript to Python compiler"
  putStrLn ""
  putStrLn "Usage: purepy [INPUT_DIR] [OUTPUT_DIR]"
  putStrLn ""
  putStrLn "Reads corefn.json files from INPUT_DIR (default: output) and"
  putStrLn "writes Python modules to OUTPUT_DIR (default: output-py)."
  putStrLn ""
  putStrLn "Typical use, from a spago project:"
  putStrLn "  spago build  (with --codegen corefn, or a backend configured)"
  putStrLn "  purepy output output-py"
  putStrLn "  python3 output-py/main.py"

printVersion :: IO ()
printVersion = putStrLn "purepy 0.0.2"
