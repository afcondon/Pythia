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
    [] -> do
      -- Default: compile from "output" to "output-py"
      compile CompileOptions
        { inputDir = "output"
        , outputDir = "output-py"
        }
    [input] -> do
      compile CompileOptions
        { inputDir = input
        , outputDir = "output-py"
        }
    [input, output] -> do
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
  putStrLn "Arguments:"
  putStrLn "  INPUT_DIR   Directory containing corefn.json files (default: output)"
  putStrLn "  OUTPUT_DIR  Directory for Python output (default: output-py)"
  putStrLn ""
  putStrLn "Options:"
  putStrLn "  -h, --help     Show this help message"
  putStrLn "  -v, --version  Show version information"
  putStrLn ""
  putStrLn "Example workflow:"
  putStrLn "  1. spago build    # Generate CoreFn in output/"
  putStrLn "  2. purepy         # Generate Python in output-py/"
  putStrLn "  3. python -c 'from output_py.main import main; main()'"

printVersion :: IO ()
printVersion = do
  putStrLn "purepy 0.0.1"
  putStrLn "PureScript to Python compiler"
  putStrLn ""
  putStrLn "Supports PureScript 0.15.x"
