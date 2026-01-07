module Test.Prelude where

import Prelude

import Control.Apply (lift2)
import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.Either (Either(..), isLeft, isRight)
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Effect.Console (log)
import Test.Assert (assert, assertEqual)

testPrelude :: Effect Unit
testPrelude = do
  log "=== Testing Prelude on Python backend ==="

  -- Eq
  log "Testing Eq..."
  assertEqual { actual: 1 == 1, expected: true }
  assertEqual { actual: 1 == 2, expected: false }
  assertEqual { actual: 1 /= 2, expected: true }
  assertEqual { actual: "hello" == "hello", expected: true }
  assertEqual { actual: true == true, expected: true }
  assertEqual { actual: [1, 2] == [1, 2], expected: true }
  assertEqual { actual: [1, 2] == [1, 3], expected: false }

  -- Ord
  log "Testing Ord..."
  assertEqual { actual: compare 1 2, expected: LT }
  assertEqual { actual: compare 2 1, expected: GT }
  assertEqual { actual: compare 1 1, expected: EQ }
  assertEqual { actual: 1 < 2, expected: true }
  assertEqual { actual: 2 > 1, expected: true }
  assertEqual { actual: 1 <= 1, expected: true }
  assertEqual { actual: 2 >= 2, expected: true }
  assertEqual { actual: min 1 2, expected: 1 }
  assertEqual { actual: max 1 2, expected: 2 }

  -- Show
  log "Testing Show..."
  assertEqual { actual: show 42, expected: "42" }
  assertEqual { actual: show true, expected: "true" }
  assertEqual { actual: show "hello", expected: "\"hello\"" }
  assertEqual { actual: show [1, 2, 3], expected: "[1,2,3]" }

  -- Semiring
  log "Testing Semiring..."
  assertEqual { actual: 2 + 3, expected: 5 }
  assertEqual { actual: 2 * 3, expected: 6 }
  assertEqual { actual: zero :: Int, expected: 0 }
  assertEqual { actual: one :: Int, expected: 1 }

  -- Ring
  log "Testing Ring..."
  assertEqual { actual: 5 - 3, expected: 2 }
  assertEqual { actual: negate 5, expected: -5 }

  -- EuclideanRing
  log "Testing EuclideanRing..."
  assertEqual { actual: 10 / 3, expected: 3 }
  assertEqual { actual: mod 10 3, expected: 1 }

  -- Boolean operations
  log "Testing Boolean operations..."
  assertEqual { actual: not true, expected: false }
  assertEqual { actual: not false, expected: true }
  assertEqual { actual: true && true, expected: true }
  assertEqual { actual: true && false, expected: false }
  assertEqual { actual: true || false, expected: true }
  assertEqual { actual: false || false, expected: false }

  -- Function composition
  log "Testing function composition..."
  let f = (_ + 1)
  let g = (_ * 2)
  assertEqual { actual: (f >>> g) 3, expected: 8 }  -- (3 + 1) * 2 = 8
  assertEqual { actual: (f <<< g) 3, expected: 7 }  -- (3 * 2) + 1 = 7
  assertEqual { actual: (f $ 3), expected: 4 }
  assertEqual { actual: (3 # f), expected: 4 }

  -- Functor (map)
  log "Testing Functor..."
  assertEqual { actual: map (_ + 1) (Just 5), expected: Just 6 }
  assertEqual { actual: map (_ + 1) Nothing, expected: Nothing }
  assertEqual { actual: map (_ + 1) [1, 2, 3], expected: [2, 3, 4] }
  assertEqual { actual: (_ + 1) <$> Just 5, expected: Just 6 }
  assertEqual { actual: void (Just 5), expected: Just unit }

  -- Apply
  log "Testing Apply..."
  assertEqual { actual: apply (Just (_ + 1)) (Just 5), expected: Just 6 }
  assertEqual { actual: Just (_ + 1) <*> Just 5, expected: Just 6 }
  assertEqual { actual: Just (_ + 1) <*> Nothing, expected: Nothing }
  assertEqual { actual: lift2 (+) (Just 2) (Just 3), expected: Just 5 }
  assertEqual { actual: Just 1 *> Just 2, expected: Just 2 }
  assertEqual { actual: Just 1 <* Just 2, expected: Just 1 }

  -- Applicative (pure)
  log "Testing Applicative..."
  assertEqual { actual: pure 5 :: Maybe Int, expected: Just 5 }
  assertEqual { actual: pure 5 :: Array Int, expected: [5] }

  -- Bind
  log "Testing Bind..."
  assertEqual { actual: bind (Just 5) (\x -> Just (x + 1)), expected: Just 6 }
  assertEqual { actual: Just 5 >>= (\x -> Just (x + 1)), expected: Just 6 }
  assertEqual { actual: Nothing >>= (\x -> Just (x + 1)), expected: Nothing }
  assertEqual { actual: join (Just (Just 5)), expected: Just 5 }

  -- Maybe
  log "Testing Maybe..."
  assertEqual { actual: isJust (Just 5), expected: true }
  assertEqual { actual: isJust Nothing, expected: false }
  assertEqual { actual: isNothing Nothing, expected: true }
  assertEqual { actual: fromMaybe 0 (Just 5), expected: 5 }
  assertEqual { actual: fromMaybe 0 Nothing, expected: 0 }

  -- Either
  log "Testing Either..."
  assertEqual { actual: isRight (Right 5 :: Either String Int), expected: true }
  assertEqual { actual: isLeft (Left "error" :: Either String Int), expected: true }
  assertEqual { actual: map (_ + 1) (Right 5 :: Either String Int), expected: Right 6 }
  assertEqual { actual: map (_ + 1) (Left "error" :: Either String Int), expected: Left "error" }

  -- Tuple
  log "Testing Tuple..."
  assertEqual { actual: fst (Tuple 1 "a"), expected: 1 }
  assertEqual { actual: snd (Tuple 1 "a"), expected: "a" }
  assertEqual { actual: Tuple 1 2 == Tuple 1 2, expected: true }
  assertEqual { actual: compare (Tuple 1 2) (Tuple 1 3), expected: LT }

  -- const and identity
  log "Testing const and identity..."
  assertEqual { actual: identity 5, expected: 5 }
  assertEqual { actual: const 5 "ignored", expected: 5 }
  assertEqual { actual: flip const 1 2, expected: 2 }

  -- Semigroup
  log "Testing Semigroup..."
  assertEqual { actual: "hello" <> " " <> "world", expected: "hello world" }
  assertEqual { actual: [1, 2] <> [3, 4], expected: [1, 2, 3, 4] }

  -- Monoid
  log "Testing Monoid..."
  assertEqual { actual: mempty :: String, expected: "" }
  assertEqual { actual: mempty :: Array Int, expected: [] }

  log "=== All prelude tests passed! ==="
