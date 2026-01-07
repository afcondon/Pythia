module Test.Arrays where

import Prelude

import Data.Array as Array
import Data.Array ((!!))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Data.Foldable (sum)
import Effect (Effect)
import Effect.Console (log)
import Test.Assert (assert, assertEqual)

testArrays :: Effect Unit
testArrays = do
  log "=== Testing Data.Array on Python backend ==="

  -- Construction
  log "Testing construction..."
  assertEqual { actual: Array.singleton 1, expected: [1] }
  assertEqual { actual: Array.range 1 5, expected: [1, 2, 3, 4, 5] }
  assertEqual { actual: Array.replicate 3 "x", expected: ["x", "x", "x"] }

  -- Basic operations
  log "Testing basic operations..."
  assertEqual { actual: Array.length [1, 2, 3], expected: 3 }
  assertEqual { actual: Array.null [], expected: true }
  assertEqual { actual: Array.null [1], expected: false }

  -- Element access
  log "Testing element access..."
  assertEqual { actual: Array.head [1, 2, 3], expected: Just 1 }
  assertEqual { actual: Array.head ([] :: Array Int), expected: Nothing }
  assertEqual { actual: Array.last [1, 2, 3], expected: Just 3 }
  assertEqual { actual: Array.tail [1, 2, 3], expected: Just [2, 3] }
  assertEqual { actual: Array.init [1, 2, 3], expected: Just [1, 2] }

  -- Indexing
  log "Testing indexing..."
  assertEqual { actual: Array.index [1, 2, 3] 0, expected: Just 1 }
  assertEqual { actual: Array.index [1, 2, 3] 2, expected: Just 3 }
  assertEqual { actual: Array.index [1, 2, 3] 5, expected: Nothing }
  assertEqual { actual: [1, 2, 3] !! 1, expected: Just 2 }

  -- Cons/Snoc
  log "Testing cons/snoc..."
  assertEqual { actual: Array.cons 0 [1, 2], expected: [0, 1, 2] }
  assertEqual { actual: Array.snoc [1, 2] 3, expected: [1, 2, 3] }

  -- Uncons/Unsnoc
  log "Testing uncons/unsnoc..."
  case Array.uncons [1, 2, 3] of
    Just { head: h, tail: t } -> do
      assertEqual { actual: h, expected: 1 }
      assertEqual { actual: t, expected: [2, 3] }
    Nothing -> assert false

  case Array.unsnoc [1, 2, 3] of
    Just { init: i, last: l } -> do
      assertEqual { actual: i, expected: [1, 2] }
      assertEqual { actual: l, expected: 3 }
    Nothing -> assert false

  -- Transformations
  log "Testing transformations..."
  assertEqual { actual: map (_ * 2) [1, 2, 3], expected: [2, 4, 6] }
  assertEqual { actual: Array.filter (_ > 2) [1, 2, 3, 4], expected: [3, 4] }
  assertEqual { actual: Array.reverse [1, 2, 3], expected: [3, 2, 1] }
  assertEqual { actual: Array.concat [[1, 2], [3, 4]], expected: [1, 2, 3, 4] }
  assertEqual { actual: Array.concatMap (\x -> [x, x]) [1, 2], expected: [1, 1, 2, 2] }

  -- Folds
  log "Testing folds..."
  assertEqual { actual: Array.foldl (+) 0 [1, 2, 3, 4], expected: 10 }
  assertEqual { actual: Array.foldr (+) 0 [1, 2, 3, 4], expected: 10 }
  assertEqual { actual: sum [1, 2, 3, 4, 5], expected: 15 }

  -- Finding
  log "Testing find operations..."
  assertEqual { actual: Array.elem 2 [1, 2, 3], expected: true }
  assertEqual { actual: Array.elem 5 [1, 2, 3], expected: false }
  assertEqual { actual: Array.find (_ > 2) [1, 2, 3, 4], expected: Just 3 }
  assertEqual { actual: Array.findIndex (_ > 2) [1, 2, 3, 4], expected: Just 2 }
  assertEqual { actual: Array.elemIndex 3 [1, 2, 3, 4], expected: Just 2 }

  -- Modification
  log "Testing modification..."
  assertEqual { actual: Array.insertAt 1 99 [1, 2, 3], expected: Just [1, 99, 2, 3] }
  assertEqual { actual: Array.deleteAt 1 [1, 2, 3], expected: Just [1, 3] }
  assertEqual { actual: Array.updateAt 1 99 [1, 2, 3], expected: Just [1, 99, 3] }
  assertEqual { actual: Array.modifyAt 1 (_ * 10) [1, 2, 3], expected: Just [1, 20, 3] }

  -- Sorting
  log "Testing sorting..."
  assertEqual { actual: Array.sort [3, 1, 4, 1, 5], expected: [1, 1, 3, 4, 5] }
  assertEqual { actual: Array.sortBy (comparing identity) [3, 1, 2], expected: [1, 2, 3] }
  assertEqual { actual: Array.nub [1, 2, 1, 3, 2], expected: [1, 2, 3] }

  -- Take/Drop
  log "Testing take/drop..."
  assertEqual { actual: Array.take 2 [1, 2, 3, 4], expected: [1, 2] }
  assertEqual { actual: Array.drop 2 [1, 2, 3, 4], expected: [3, 4] }
  assertEqual { actual: Array.takeWhile (_ < 3) [1, 2, 3, 4], expected: [1, 2] }
  assertEqual { actual: Array.dropWhile (_ < 3) [1, 2, 3, 4], expected: [3, 4] }

  -- Span/Group
  log "Testing span/group..."
  case Array.span (_ < 3) [1, 2, 3, 4, 1] of
    { init: i, rest: r } -> do
      assertEqual { actual: i, expected: [1, 2] }
      assertEqual { actual: r, expected: [3, 4, 1] }

  -- Zip
  log "Testing zip..."
  assertEqual { actual: Array.zip [1, 2] ["a", "b"], expected: [Tuple 1 "a", Tuple 2 "b"] }
  assertEqual { actual: Array.zipWith (+) [1, 2] [10, 20], expected: [11, 22] }

  log "=== All array tests passed! ==="
