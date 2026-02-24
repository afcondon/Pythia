module Test.CrossBackend.Strings where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String.CodeUnits as CU
import Data.String.CodePoints as CP
import Data.String.Common as SC
import Effect (Effect)
import Effect.Console (log)

-- | Cross-backend string tests.
-- | Each test prints "TEST <name>: <value>" for comparison between JS and Python.
main :: Effect Unit
main = do
  log "=== CrossBackend.Strings ==="

  -- Basic string operations
  log $ "TEST length-ascii: " <> show (CU.length "hello")
  log $ "TEST length-empty: " <> show (CU.length "")
  log $ "TEST length-unicode-bmp: " <> show (CU.length "café")

  -- Emoji / non-BMP: THIS IS WHERE JS AND PYTHON DIVERGE
  -- JS: "😀".length === 2 (surrogate pair), Python: len("😀") === 1
  log $ "TEST length-emoji: " <> show (CU.length "😀")
  log $ "TEST length-two-emoji: " <> show (CU.length "😀🎉")
  log $ "TEST length-mixed-emoji: " <> show (CU.length "a😀b")

  -- Code points length (should agree across backends)
  log $ "TEST cp-length-emoji: " <> show (CP.length "😀")
  log $ "TEST cp-length-two-emoji: " <> show (CP.length "😀🎉")
  log $ "TEST cp-length-mixed: " <> show (CP.length "a😀b")

  -- charAt
  log $ "TEST charAt-0-hello: " <> show (CU.charAt 0 "hello")
  log $ "TEST charAt-4-hello: " <> show (CU.charAt 4 "hello")
  log $ "TEST charAt-5-hello: " <> show (CU.charAt 5 "hello")
  log $ "TEST charAt-0-emoji: " <> show (CU.charAt 0 "😀x")

  -- indexOf
  log $ "TEST indexOf-ll: " <> show (CU.indexOf (CU.Pattern "ll") "hello")
  log $ "TEST indexOf-x: " <> show (CU.indexOf (CU.Pattern "x") "hello")
  log $ "TEST indexOf-empty: " <> show (CU.indexOf (CU.Pattern "") "hello")

  -- take / drop
  log $ "TEST take-3: " <> show (CU.take 3 "hello")
  log $ "TEST drop-3: " <> show (CU.drop 3 "hello")
  log $ "TEST take-0: " <> show (CU.take 0 "hello")
  log $ "TEST drop-0: " <> show (CU.drop 0 "hello")

  -- take/drop with emoji (divergence expected)
  log $ "TEST take-1-emoji: " <> show (CU.take 1 "😀hello")
  log $ "TEST take-2-emoji: " <> show (CU.take 2 "😀hello")

  -- splitAt
  let split3 = CU.splitAt 3 "hello"
  log $ "TEST splitAt-3-before: " <> show split3.before
  log $ "TEST splitAt-3-after: " <> show split3.after

  -- toCharArray
  log $ "TEST toCharArray-hi: " <> show (CU.toCharArray "hi")
  log $ "TEST toCharArray-emoji: " <> show (CU.toCharArray "😀")

  -- String.Common operations (should agree)
  log $ "TEST toLower: " <> show (SC.toLower "HELLO")
  log $ "TEST toUpper: " <> show (SC.toUpper "hello")
  log $ "TEST trim: " <> show (SC.trim "  hello  ")
  log $ "TEST replace: " <> show (SC.replace (SC.Pattern "foo") (SC.Replacement "bar") "foo baz foo")
  log $ "TEST replaceAll: " <> show (SC.replaceAll (SC.Pattern "foo") (SC.Replacement "bar") "foo baz foo")
  log $ "TEST split: " <> show (SC.split (SC.Pattern ",") "a,b,c")
  log $ "TEST joinWith: " <> show (SC.joinWith ", " ["a", "b", "c"])

  -- Code points operations (should agree across backends)
  log $ "TEST cp-toCodePointArray-hi: " <> show (CP.toCodePointArray "hi")
  log $ "TEST cp-toCodePointArray-emoji: " <> show (CP.toCodePointArray "😀")

  -- Singleton
  log $ "TEST singleton-a: " <> show (CU.singleton 'a')

  -- countPrefix
  log $ "TEST countPrefix-a: " <> show (CU.countPrefix (\c -> c == 'a') "aaab")
  log $ "TEST countPrefix-none: " <> show (CU.countPrefix (\c -> c == 'a') "baaa")

  log "=== Done ==="
