-- | Visual demonstration of async concurrency
-- |
-- | This demo shows interleaved output from concurrent tasks,
-- | proving that they run in parallel, not sequentially.
module Demo.AsyncioVisual where

import Prelude

import Control.Monad.Asyncio as Asyncio
import Control.Monad.Asyncio (Asyncio)
import Data.Array ((..))
import Data.Foldable (for_)
import Effect (Effect)
import Effect.Class.Console (log)
import Unsafe.Coerce (unsafeCoerce)

-- | Convert Int to Number (milliseconds)
intToNumber :: Int -> Number
intToNumber = unsafeCoerce

-- | A worker that logs its progress at intervals
worker :: String -> Int -> Int -> Asyncio Unit
worker name steps delayMs = do
  for_ (1 .. steps) \i -> do
    Asyncio.liftEffect $ log $ "  [" <> name <> "] Step " <> show i <> "/" <> show steps
    Asyncio.sleep (intToNumber delayMs)
  Asyncio.liftEffect $ log $ "  [" <> name <> "] Done!"

-- | Demo 1: Sequential execution (slow)
sequentialDemo :: Asyncio Unit
sequentialDemo = do
  Asyncio.liftEffect $ log "\n━━━ SEQUENTIAL (one after another) ━━━"
  Asyncio.liftEffect $ log "Starting Worker A..."
  worker "A" 3 100
  Asyncio.liftEffect $ log "Starting Worker B..."
  worker "B" 3 100
  Asyncio.liftEffect $ log "Starting Worker C..."
  worker "C" 3 100

-- | Demo 2: Concurrent execution (fast, interleaved output)
concurrentDemo :: Asyncio Unit
concurrentDemo = do
  Asyncio.liftEffect $ log "\n━━━ CONCURRENT (interleaved) ━━━"
  Asyncio.liftEffect $ log "Forking all workers at once..."

  -- Fork all three workers - they run concurrently
  taskA <- Asyncio.fork $ worker "A" 5 80
  taskB <- Asyncio.fork $ worker "B" 5 120
  taskC <- Asyncio.fork $ worker "C" 5 60

  Asyncio.liftEffect $ log "All forked! Watch the interleaved output:\n"

  -- Wait for all to complete
  _ <- Asyncio.await taskA
  _ <- Asyncio.await taskB
  _ <- Asyncio.await taskC

  Asyncio.liftEffect $ log "\nAll workers finished!"

-- | Demo 3: Race - first one wins
raceDemo :: Asyncio Unit
raceDemo = do
  Asyncio.liftEffect $ log "\n━━━ RACE (first to finish wins) ━━━"

  let slowTask = do
        Asyncio.liftEffect $ log "  [SLOW] Starting (will take 500ms)..."
        Asyncio.sleep 500.0
        Asyncio.liftEffect $ log "  [SLOW] Finished!"
        pure "SLOW"

  let fastTask = do
        Asyncio.liftEffect $ log "  [FAST] Starting (will take 100ms)..."
        Asyncio.sleep 100.0
        Asyncio.liftEffect $ log "  [FAST] Finished!"
        pure "FAST"

  winner <- Asyncio.race slowTask fastTask
  Asyncio.liftEffect $ log $ "Winner: " <> winner <> " (loser was cancelled)"

-- | Demo 4: Countdown with live updates
countdownDemo :: Asyncio Unit
countdownDemo = do
  Asyncio.liftEffect $ log "\n━━━ COUNTDOWN ━━━"
  for_ [5, 4, 3, 2, 1] \n -> do
    Asyncio.liftEffect $ log $ "  " <> show n <> "..."
    Asyncio.sleep 200.0
  Asyncio.liftEffect $ log "  🚀 Liftoff!"

-- | Demo 5: Parallel fetch simulation
parallelFetchDemo :: Asyncio Unit
parallelFetchDemo = do
  Asyncio.liftEffect $ log "\n━━━ PARALLEL FETCH (simulated) ━━━"
  Asyncio.liftEffect $ log "Fetching from 5 APIs concurrently..."

  let fetchAPI name delayMs = do
        Asyncio.liftEffect $ log $ "  📡 " <> name <> " starting..."
        Asyncio.sleep (intToNumber delayMs)
        Asyncio.liftEffect $ log $ "  ✅ " <> name <> " complete!"
        pure $ name <> ": OK"

  _ <- Asyncio.parallelImpl
    [ fetchAPI "users-api" 150
    , fetchAPI "orders-api" 200
    , fetchAPI "products-api" 100
    , fetchAPI "analytics-api" 180
    , fetchAPI "notifications-api" 120
    ]

  Asyncio.liftEffect $ log "\nAll 5 APIs responded!"

-- | Main entry point
main :: Effect Unit
main = Asyncio.run_ do
  Asyncio.liftEffect $ log "╔════════════════════════════════════════╗"
  Asyncio.liftEffect $ log "║     ASYNCIO CONCURRENCY DEMO           ║"
  Asyncio.liftEffect $ log "╚════════════════════════════════════════╝"

  countdownDemo
  concurrentDemo
  raceDemo
  parallelFetchDemo

  Asyncio.liftEffect $ log "\n✨ All demos complete!"
