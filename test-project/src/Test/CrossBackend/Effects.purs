module Test.CrossBackend.Effects where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Effect.Ref as Ref

-- | Cross-backend effect tests.
-- | Tests effect sequencing, mutable references, and basic control flow.
main :: Effect Unit
main = do
  log "=== CrossBackend.Effects ==="

  -- Basic effect sequencing
  log "TEST seq-1: first"
  log "TEST seq-2: second"
  log "TEST seq-3: third"

  -- Ref: create, read, write, modify
  ref <- Ref.new 0
  v0 <- Ref.read ref
  log $ "TEST ref-initial: " <> show v0

  Ref.write 42 ref
  v1 <- Ref.read ref
  log $ "TEST ref-write: " <> show v1

  Ref.modify_ (_ + 8) ref
  v2 <- Ref.read ref
  log $ "TEST ref-modify: " <> show v2

  -- Multiple refs
  a <- Ref.new 10
  b <- Ref.new 20
  va <- Ref.read a
  vb <- Ref.read b
  Ref.write (va + vb) a
  result <- Ref.read a
  log $ "TEST ref-multi: " <> show result

  -- Effect in loops (via recursion)
  counter <- Ref.new 0
  let
    loop :: Int -> Effect Unit
    loop 0 = pure unit
    loop n = do
      Ref.modify_ (_ + 1) counter
      loop (n - 1)
  loop 10
  countVal <- Ref.read counter
  log $ "TEST ref-loop: " <> show countVal

  -- Pure vs Effect
  let pureVal = 1 + 2 + 3 :: Int
  log $ "TEST pure-val: " <> show pureVal

  -- Void / discard
  _ <- Ref.new "ignored"
  log "TEST void-ok: true"

  -- Map over Effect
  let effVal = pure 21 :: Effect Int
  doubled <- map (_ * 2) effVal
  log $ "TEST effect-map: " <> show doubled

  -- Bind
  let
    addOne :: Int -> Effect Int
    addOne x = pure (x + 1)
  result2 <- pure 40 >>= addOne >>= addOne
  log $ "TEST effect-bind: " <> show result2

  -- Apply
  let
    f = pure (_ + 10) :: Effect (Int -> Int)
    x = pure 32 :: Effect Int
  applied <- f <*> x
  log $ "TEST effect-apply: " <> show applied

  log "=== Done ==="
