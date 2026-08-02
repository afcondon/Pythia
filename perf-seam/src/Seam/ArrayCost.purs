module Seam.ArrayCost (main) where
-- | Which half of the payload axis is the cost — MOVING the array, or
-- | PureScript LOOKING at it?
-- |
-- | The payload axis measures a foreign call that returns `n` Numbers and a
-- | PureScript fold over them, so its per-element figure conflates two very
-- | different things. This separates them: the same call, once taking only
-- | `Array.length` (the array crosses but is never iterated) and once folding
-- | every element.
-- |
-- | Measured 2026-08-02, Pythia, 8,192 samples = 16,384 Numbers:
-- |
-- |     pass through, length only    4,402 us
-- |     fold every element           6,090 us
-- |     difference                   1,688 us  =  103 ns per element
-- |
-- | So the payload cost is **the fold, not the crossing**. On purepy an
-- | `Array Number` IS the Python list the foreign returned — handing it across
-- | copies nothing, and a program that passes it straight to another foreign
-- | (as the Embedding Explorer does with its 250,000-element vectors) pays
-- | almost nothing. The bill arrives only when PureScript iterates.
-- |
-- | That distinction matters for the design rule. "Return the answer, not the
-- | data" is too blunt: returning data is fine if you are only going to hand
-- | it onward. What is expensive is *consuming* it.
-- |
-- |     .venv/bin/python -c "import sys; sys.path.insert(0,'output-py'); \
-- |         import Seam_ArrayCost; Seam_ArrayCost.main()"
import Prelude
import Data.Array as Array
import Effect (Effect, forE)
import Effect.Console (log)
import Effect.Ref as Ref
import Seam.Kernel (nowNs, flushOut, callLibraryPayload)

reps :: Int
reps = 20

-- Does the array cost anything if PureScript never LOOKS at it?
passThrough :: Int -> Effect Number
passThrough n = do
  best <- Ref.new 1.0e18
  forE 0 reps \_ -> do
    t0 <- nowNs
    let xs = callLibraryPayload 9.54e-4 0.45 0.05 0.33 n
    -- length only: purepy has the list; it never iterates it element by element
    let k = Array.length xs
    t1 <- nowNs
    when (k < 0) (log "unreachable")
    Ref.modify_ (min (t1 - t0)) best
  Ref.read best

-- And if it DOES look at every element?
foldAll :: Int -> Effect Number
foldAll n = do
  best <- Ref.new 1.0e18
  forE 0 reps \_ -> do
    t0 <- nowNs
    let xs = callLibraryPayload 9.54e-4 0.45 0.05 0.33 n
    let s = Array.foldl (+) 0.0 xs
    t1 <- nowNs
    when (s == 1.0e300) (log "unreachable")
    Ref.modify_ (min (t1 - t0)) best
  Ref.read best

main :: Effect Unit
main = do
  a <- passThrough 8192
  b <- foldAll 8192
  log ("PASSTHROUGH " <> show (a / 1000.0))
  log ("FOLD " <> show (b / 1000.0))
  flushOut
