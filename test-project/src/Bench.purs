module Bench where

import Prelude

-- | Naive recursive fibonacci
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

-- | Higher-order function composition
compose3 :: forall a b c d. (c -> d) -> (b -> c) -> (a -> b) -> a -> d
compose3 f g h x = f (g (h x))

-- | Apply composed function many times
applyN :: forall a. (a -> a) -> Int -> a -> a
applyN f n x
  | n <= 0 = x
  | otherwise = applyN f (n - 1) (f x)

-- | Increment function for testing
inc :: Int -> Int
inc x = x + 1

-- | Sum from 1 to n (tail-recursive style)
sumTo :: Int -> Int -> Int
sumTo acc n
  | n <= 0 = acc
  | otherwise = sumTo (acc + n) (n - 1)

-- | Export benchmark results as a record
-- Note: Using smaller values to avoid Python's recursion limit
benchmarks :: { fib30 :: Int
              , treeSum :: Int
              , applyInc :: Int
              , sumTo100 :: Int
              }
benchmarks =
  { fib30: fib 30
  , treeSum: sumTree (buildTree 15)
  , applyInc: applyN inc 100 0   -- Limited by Python recursion (each call = ~10 stack frames)
  , sumTo100: sumTo 0 100        -- Limited by Python recursion (each call = ~10 stack frames)
  }
