module Main where

import Prelude
import Effect (Effect)
import Test.PythonFFI (testPythonFFI)

main :: Effect Unit
main = testPythonFFI
