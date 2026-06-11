-- | Benchmark workloads, kept name-for-name and scale-for-scale compatible
-- | with the first incarnation's `Bench.purs` (whose measured numbers are
-- | recorded in docs/ROADMAP.md: fib30 22.4x, treeSum 3.2x, applyInc 20x,
-- | sumTo100 18x over hand-written Python) so before/after is meaningful.
-- |
-- | Everything is exported as plain functions: the runner imports the
-- | generated module and applies them (curried) itself, so nothing heavy
-- | runs at module-import time.
-- |
-- | One addition: `sumTo 0 1000000` — the old backend capped tail recursion
-- | at ~100 iterations ("limited by Python recursion"); the rebooted backend
-- | trampolines guard-style self-tail-recursion (the corpus's
-- | INT64-sumTo-1e6), so a million iterations is now a workload rather than
-- | a crash.
module Bench where

import Prelude

-- | Naive recursive fibonacci (NOT tail recursive: real call overhead)
fib :: Int -> Int
fib n
  | n <= 1 = n
  | otherwise = fib (n - 1) + fib (n - 2)

-- | Pattern matching on ADT
data Tree a = Leaf a | Branch (Tree a) (Tree a)

sumTree :: Tree Int -> Int
sumTree (Leaf x) = x
sumTree (Branch l r) = sumTree l + sumTree r

-- | Build a balanced tree
buildTree :: Int -> Tree Int
buildTree 0 = Leaf 1
buildTree n = Branch (buildTree (n - 1)) (buildTree (n - 1))

-- | Apply a function n times (self-tail-recursive: trampolined)
applyN :: forall a. (a -> a) -> Int -> a -> a
applyN f n x
  | n <= 0 = x
  | otherwise = applyN f (n - 1) (f x)

inc :: Int -> Int
inc x = x + 1

applyInc :: Int -> Int
applyInc n = applyN inc n 0

-- | Sum from 1 to n (self-tail-recursive: trampolined)
sumTo :: Int -> Int -> Int
sumTo acc n
  | n <= 0 = acc
  | otherwise = sumTo (acc + n) (n - 1)
