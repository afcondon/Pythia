module Test.CrossBackend.Arrays where

import Prelude

import Data.Array as A
import Data.Maybe (Maybe(..))
import Data.Foldable (foldl, foldr, sum)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console (log)

-- | Cross-backend array tests.
main :: Effect Unit
main = do
  log "=== CrossBackend.Arrays ==="

  -- Construction
  log $ "TEST range: " <> show (A.range 1 5)
  log $ "TEST replicate: " <> show (A.replicate 3 "x")
  log $ "TEST singleton: " <> show (A.singleton 42)
  log $ "TEST empty: " <> show ([] :: Array Int)
  log $ "TEST literal: " <> show [1, 2, 3, 4, 5]

  -- Basic operations
  log $ "TEST length: " <> show (A.length [1, 2, 3])
  log $ "TEST length-empty: " <> show (A.length ([] :: Array Int))
  log $ "TEST null-empty: " <> show (A.null ([] :: Array Int))
  log $ "TEST null-nonempty: " <> show (A.null [1])

  -- Indexing
  log $ "TEST index-0: " <> show (A.index [10, 20, 30] 0)
  log $ "TEST index-2: " <> show (A.index [10, 20, 30] 2)
  log $ "TEST index-oob: " <> show (A.index [10, 20, 30] 5)
  log $ "TEST index-neg: " <> show (A.index [10, 20, 30] (-1))

  -- Head / tail / init / last
  log $ "TEST head: " <> show (A.head [1, 2, 3])
  log $ "TEST head-empty: " <> show (A.head ([] :: Array Int))
  log $ "TEST tail: " <> show (A.tail [1, 2, 3])
  log $ "TEST last: " <> show (A.last [1, 2, 3])
  log $ "TEST init: " <> show (A.init [1, 2, 3])

  -- Cons / snoc
  log $ "TEST cons: " <> show (A.cons 0 [1, 2, 3])
  log $ "TEST snoc: " <> show (A.snoc [1, 2, 3] 4)

  -- Transformations
  log $ "TEST map: " <> show (map (_ * 2) [1, 2, 3])
  log $ "TEST filter: " <> show (A.filter (_ > 2) [1, 2, 3, 4, 5])
  log $ "TEST mapMaybe: " <> show (A.mapMaybe (\x -> if x > 2 then Just (x * 10) else Nothing) [1, 2, 3, 4])
  log $ "TEST concatMap: " <> show (A.concatMap (\x -> [x, x * 10]) [1, 2, 3])
  log $ "TEST reverse: " <> show (A.reverse [1, 2, 3])
  log $ "TEST concat: " <> show (A.concat [[1, 2], [3, 4], [5]])

  -- Folds
  log $ "TEST foldl: " <> show (foldl (\acc x -> acc + x) 0 [1, 2, 3, 4, 5])
  log $ "TEST foldr: " <> show (foldr (\x acc -> acc <> show x) "" [1, 2, 3])
  log $ "TEST sum: " <> show (sum [1, 2, 3, 4, 5])

  -- Sort
  log $ "TEST sort: " <> show (A.sort [3, 1, 4, 1, 5, 9, 2, 6])
  log $ "TEST sortBy: " <> show (A.sortBy (flip compare) [3, 1, 4, 1, 5])

  -- Take / drop
  log $ "TEST take-3: " <> show (A.take 3 [1, 2, 3, 4, 5])
  log $ "TEST take-0: " <> show (A.take 0 [1, 2, 3])
  log $ "TEST take-10: " <> show (A.take 10 [1, 2, 3])
  log $ "TEST drop-2: " <> show (A.drop 2 [1, 2, 3, 4, 5])

  -- Zip
  log $ "TEST zip: " <> show (A.zip [1, 2, 3] ["a", "b", "c"])
  log $ "TEST zipWith: " <> show (A.zipWith (+) [1, 2, 3] [10, 20, 30])

  -- Find
  log $ "TEST find: " <> show (A.find (_ > 3) [1, 2, 3, 4, 5])
  log $ "TEST findIndex: " <> show (A.findIndex (_ > 3) [1, 2, 3, 4, 5])
  log $ "TEST elem: " <> show (A.elem 3 [1, 2, 3, 4, 5])
  log $ "TEST elem-missing: " <> show (A.elem 6 [1, 2, 3, 4, 5])

  -- Nub (remove duplicates)
  log $ "TEST nub: " <> show (A.nub [1, 2, 1, 3, 2, 4])

  -- Slice
  log $ "TEST slice: " <> show (A.slice 1 4 [10, 20, 30, 40, 50])

  -- Uncons
  log $ "TEST uncons: " <> show (A.uncons [1, 2, 3])
  log $ "TEST uncons-empty: " <> show (A.uncons ([] :: Array Int))

  -- Large array operations
  let bigArr = A.range 1 1000
  log $ "TEST large-length: " <> show (A.length bigArr)
  log $ "TEST large-sum: " <> show (sum bigArr)
  log $ "TEST large-filter: " <> show (A.length (A.filter (_ > 500) bigArr))

  log "=== Done ==="
