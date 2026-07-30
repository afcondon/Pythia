-- | Tests for Python FFI implementations
-- | These tests verify that our Python FFI works correctly when
-- | compiled from PureScript through purepy.
module Test.PythonFFI where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Int as Int
import Data.Lazy as Lazy
import Data.Maybe (Maybe(..))
import Data.Number as Number
import Data.String as String
import Data.String.CodeUnits as SCU
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception as Exception
import Effect.Ref as Ref
import Test.Assert (assert, assertEqual)

-- | Main test runner
testPythonFFI :: Effect Unit
testPythonFFI = do
  log "=== Python FFI Tests ==="

  testPrelude
  testArray
  testInt
  testNumber
  testString
  testRef
  testLazy
  testException

  log "=== All Python FFI tests passed! ==="

testPrelude :: Effect Unit
testPrelude = do
  log "Testing Prelude..."

  -- Basic operations
  assertEqual { actual: 1 + 2, expected: 3 }
  assertEqual { actual: 10 - 3, expected: 7 }
  assertEqual { actual: 4 * 5, expected: 20 }
  assertEqual { actual: 10 / 2, expected: 5 }

  -- Comparison
  assert (1 < 2)
  assert (2 > 1)
  assert (2 == 2)
  assert (1 /= 2)

  -- Show
  assertEqual { actual: show 42, expected: "42" }
  assertEqual { actual: show true, expected: "true" }

  log "  ✓ Prelude tests passed"

testArray :: Effect Unit
testArray = do
  log "Testing Data.Array..."

  -- Basic operations
  assertEqual { actual: Array.length [1, 2, 3], expected: 3 }
  assertEqual { actual: Array.null [], expected: true }
  assertEqual { actual: Array.null [1], expected: false }

  -- cons and snoc
  assertEqual { actual: Array.cons 0 [1, 2], expected: [0, 1, 2] }
  assertEqual { actual: Array.snoc [1, 2] 3, expected: [1, 2, 3] }

  -- head and tail
  assertEqual { actual: Array.head [1, 2, 3], expected: Just 1 }
  assertEqual { actual: Array.head ([] :: Array Int), expected: Nothing }
  assertEqual { actual: Array.tail [1, 2, 3], expected: Just [2, 3] }

  -- index
  assertEqual { actual: Array.index [10, 20, 30] 1, expected: Just 20 }
  assertEqual { actual: Array.index [10, 20, 30] 10, expected: Nothing }

  -- map and filter
  assertEqual { actual: map (_ * 2) [1, 2, 3], expected: [2, 4, 6] }
  assertEqual { actual: Array.filter (_ > 2) [1, 2, 3, 4], expected: [3, 4] }

  -- fold
  assertEqual { actual: Array.foldl (+) 0 [1, 2, 3, 4], expected: 10 }
  assertEqual { actual: Array.foldr (-) 0 [1, 2, 3], expected: 2 } -- 1 - (2 - (3 - 0))

  -- reverse and concat
  assertEqual { actual: Array.reverse [1, 2, 3], expected: [3, 2, 1] }
  assertEqual { actual: Array.concat [[1, 2], [3, 4]], expected: [1, 2, 3, 4] }

  log "  ✓ Array tests passed"

testInt :: Effect Unit
testInt = do
  log "Testing Data.Int..."

  -- fromNumber
  assertEqual { actual: Int.fromNumber 42.0, expected: Just 42 }
  assertEqual { actual: Int.fromNumber 3.14, expected: Nothing }

  -- toNumber
  assertEqual { actual: Int.toNumber 42, expected: 42.0 }

  -- toStringAs
  assertEqual { actual: Int.toStringAs Int.decimal 42, expected: "42" }
  assertEqual { actual: Int.toStringAs Int.hexadecimal 255, expected: "ff" }
  assertEqual { actual: Int.toStringAs Int.binary 5, expected: "101" }

  -- quot and rem
  assertEqual { actual: Int.quot 7 3, expected: 2 }
  assertEqual { actual: Int.rem 7 3, expected: 1 }

  log "  ✓ Int tests passed"

testNumber :: Effect Unit
testNumber = do
  log "Testing Data.Number..."

  -- fromString
  assertEqual { actual: Number.fromString "3.14", expected: Just 3.14 }
  assertEqual { actual: Number.fromString "not a number", expected: Nothing }

  -- isNaN and isFinite
  assert (Number.isNaN Number.nan)
  assert (not (Number.isFinite Number.infinity))
  assert (Number.isFinite 42.0)

  -- Math operations
  assertEqual { actual: Number.floor 3.7, expected: 3.0 }
  assertEqual { actual: Number.ceil 3.2, expected: 4.0 }
  assertEqual { actual: Number.trunc (-3.7), expected: -3.0 }

  -- sign
  assertEqual { actual: Number.sign 5.0, expected: 1.0 }
  assertEqual { actual: Number.sign (-5.0), expected: -1.0 }

  log "  ✓ Number tests passed"

testString :: Effect Unit
testString = do
  log "Testing Data.String..."

  -- Basic string operations
  assertEqual { actual: String.toLower "HELLO", expected: "hello" }
  assertEqual { actual: String.toUpper "hello", expected: "HELLO" }
  assertEqual { actual: String.trim "  hello  ", expected: "hello" }

  -- replace
  assertEqual { actual: String.replace (String.Pattern "foo") (String.Replacement "bar") "foo baz foo"
              , expected: "bar baz foo" }
  assertEqual { actual: String.replaceAll (String.Pattern "foo") (String.Replacement "bar") "foo baz foo"
              , expected: "bar baz bar" }

  -- split and joinWith
  assertEqual { actual: String.split (String.Pattern ",") "a,b,c", expected: ["a", "b", "c"] }
  assertEqual { actual: String.joinWith ", " ["a", "b", "c"], expected: "a, b, c" }

  -- CodeUnits
  assertEqual { actual: SCU.length "hello", expected: 5 }
  assertEqual { actual: SCU.take 3 "hello", expected: "hel" }
  assertEqual { actual: SCU.drop 3 "hello", expected: "lo" }
  assertEqual { actual: SCU.charAt 0 "hello", expected: Just 'h' }
  assertEqual { actual: SCU.indexOf (String.Pattern "ll") "hello", expected: Just 2 }

  log "  ✓ String tests passed"

testRef :: Effect Unit
testRef = do
  log "Testing Effect.Ref..."

  -- Create and read
  ref <- Ref.new 10
  val1 <- Ref.read ref
  assertEqual { actual: val1, expected: 10 }

  -- Write
  Ref.write 20 ref
  val2 <- Ref.read ref
  assertEqual { actual: val2, expected: 20 }

  -- Modify
  Ref.modify_ (_ + 5) ref
  val3 <- Ref.read ref
  assertEqual { actual: val3, expected: 25 }

  log "  ✓ Ref tests passed"

testLazy :: Effect Unit
testLazy = do
  log "Testing Data.Lazy..."

  -- Create and force lazy value
  let lazy = Lazy.defer \_ -> 42
  assertEqual { actual: Lazy.force lazy, expected: 42 }

  -- Verify memoization (can't directly test in pure code, but verify it works)
  let lazy2 = Lazy.defer \_ -> 1 + 2
  assertEqual { actual: Lazy.force lazy2, expected: 3 }
  assertEqual { actual: Lazy.force lazy2, expected: 3 }  -- Same result

  log "  ✓ Lazy tests passed"

testException :: Effect Unit
testException = do
  log "Testing Effect.Exception..."

  -- Create and inspect error
  let err = Exception.error "test error"
  assertEqual { actual: Exception.message err, expected: "test error" }

  -- Try/catch pattern
  result <- Exception.try do
    pure 42
  case result of
    Left _ -> assert false  -- Should not fail
    Right val -> assertEqual { actual: val, expected: 42 }

  log "  ✓ Exception tests passed"
