module Test.CrossBackend.ADTs where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.Either (Either(..), isLeft, isRight)
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Effect.Console (log)

-- | Local ADT for testing
data Color = Red | Green | Blue

derive instance eqColor :: Eq Color

showColor :: Color -> String
showColor Red = "Red"
showColor Green = "Green"
showColor Blue = "Blue"

data Shape
  = Circle Number
  | Rectangle Number Number
  | Triangle Number Number Number

area :: Shape -> Number
area (Circle r) = 3.14159 * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) =
  let s = (a + b + c) / 2.0
  in s * (s - a) * (s - b) * (s - c)

-- | Nested ADT
data Tree a = Leaf a | Branch (Tree a) (Tree a)

treeSize :: forall a. Tree a -> Int
treeSize (Leaf _) = 1
treeSize (Branch l r) = treeSize l + treeSize r

treeDepth :: forall a. Tree a -> Int
treeDepth (Leaf _) = 0
treeDepth (Branch l r) = 1 + max (treeDepth l) (treeDepth r)

-- | Cross-backend ADT tests.
main :: Effect Unit
main = do
  log "=== CrossBackend.ADTs ==="

  -- Maybe
  log $ "TEST maybe-just: " <> show (Just 42)
  log $ "TEST maybe-nothing: " <> show (Nothing :: Maybe Int)
  log $ "TEST maybe-isJust: " <> show (isJust (Just 42))
  log $ "TEST maybe-isNothing: " <> show (isNothing (Nothing :: Maybe Int))
  log $ "TEST maybe-fromMaybe: " <> show (fromMaybe 0 (Just 42))
  log $ "TEST maybe-fromMaybe-nothing: " <> show (fromMaybe 0 (Nothing :: Maybe Int))
  log $ "TEST maybe-map: " <> show (map (_ + 1) (Just 41))
  log $ "TEST maybe-bind: " <> show (Just 21 >>= \x -> Just (x * 2))

  -- Either
  log $ "TEST either-right: " <> show (Right 42 :: Either String Int)
  log $ "TEST either-left: " <> show (Left "error" :: Either String Int)
  log $ "TEST either-isRight: " <> show (isRight (Right 42 :: Either String Int))
  log $ "TEST either-isLeft: " <> show (isLeft (Left "error" :: Either String Int))
  log $ "TEST either-map: " <> show (map (_ + 1) (Right 41 :: Either String Int))

  -- Tuple
  log $ "TEST tuple: " <> show (Tuple 1 "hello")
  log $ "TEST tuple-fst: " <> show (fst (Tuple 1 "hello"))
  log $ "TEST tuple-snd: " <> show (snd (Tuple 1 "hello"))

  -- Local ADTs
  log $ "TEST color-eq: " <> show (Red == Red)
  log $ "TEST color-neq: " <> show (Red == Blue)
  log $ "TEST color-show: " <> showColor Green

  -- Pattern matching
  log $ "TEST area-circle: " <> show (area (Circle 5.0))
  log $ "TEST area-rect: " <> show (area (Rectangle 3.0 4.0))

  -- Nested ADT
  let tree = Branch (Branch (Leaf 1) (Leaf 2)) (Leaf 3)
  log $ "TEST tree-size: " <> show (treeSize tree)
  log $ "TEST tree-depth: " <> show (treeDepth tree)

  -- Ordering
  log $ "TEST ordering-lt: " <> show (compare 1 2)
  log $ "TEST ordering-eq: " <> show (compare 1 1)
  log $ "TEST ordering-gt: " <> show (compare 2 1)

  -- Show instances
  log $ "TEST show-int: " <> show 42
  log $ "TEST show-number: " <> show 3.14
  log $ "TEST show-string: " <> show "hello"
  log $ "TEST show-bool: " <> show true
  log $ "TEST show-array: " <> show [1, 2, 3]
  log $ "TEST show-unit: " <> show unit

  log "=== Done ==="
