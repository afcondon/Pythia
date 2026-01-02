module Demo.AsyncioDemo where

import Prelude

import Control.Monad.Asyncio as Asyncio
import Control.Monad.Asyncio (Asyncio)
import Effect (Effect)
import Effect.Console (log)

-- | Simple async computation that sleeps and returns a value
delayedValue :: forall a. Number -> a -> Asyncio a
delayedValue ms value = do
  Asyncio.sleep ms
  pure value

-- | Demo: Sequential async operations
sequentialDemo :: Asyncio String
sequentialDemo = do
  _ <- Asyncio.liftEffect (log "Starting sequential demo...")
  a <- delayedValue 100.0 "First"
  _ <- Asyncio.liftEffect (log $ "Got: " <> a)
  b <- delayedValue 100.0 "Second"
  _ <- Asyncio.liftEffect (log $ "Got: " <> b)
  c <- delayedValue 100.0 "Third"
  _ <- Asyncio.liftEffect (log $ "Got: " <> c)
  pure (a <> ", " <> b <> ", " <> c)

-- | Demo: Concurrent async operations using fork/await
concurrentDemo :: Asyncio String
concurrentDemo = do
  _ <- Asyncio.liftEffect (log "Starting concurrent demo...")

  -- Fork three tasks that run concurrently
  task1 <- Asyncio.fork (delayedValue 300.0 "Task1")
  task2 <- Asyncio.fork (delayedValue 200.0 "Task2")
  task3 <- Asyncio.fork (delayedValue 100.0 "Task3")

  _ <- Asyncio.liftEffect (log "All tasks forked, awaiting results...")

  -- Await all results
  result3 <- Asyncio.await task3  -- Should complete first (100ms)
  _ <- Asyncio.liftEffect (log $ "Got: " <> result3)

  result2 <- Asyncio.await task2  -- Should complete second (200ms)
  _ <- Asyncio.liftEffect (log $ "Got: " <> result2)

  result1 <- Asyncio.await task1  -- Should complete last (300ms)
  _ <- Asyncio.liftEffect (log $ "Got: " <> result1)

  pure (result1 <> ", " <> result2 <> ", " <> result3)

-- | Demo: Parallel execution using parallelImpl
parallelDemo :: Asyncio (Array String)
parallelDemo = do
  _ <- Asyncio.liftEffect (log "Starting parallel demo...")

  results <- Asyncio.parallelImpl
    [ delayedValue 100.0 "A"
    , delayedValue 150.0 "B"
    , delayedValue 50.0 "C"
    ]

  _ <- Asyncio.liftEffect (log $ "All completed!")
  pure results

-- | Demo: Race between two computations
raceDemo :: Asyncio String
raceDemo = do
  _ <- Asyncio.liftEffect (log "Starting race demo...")

  winner <- Asyncio.race
    (delayedValue 200.0 "Slow")
    (delayedValue 100.0 "Fast")

  _ <- Asyncio.liftEffect (log $ "Winner: " <> winner)
  pure winner

-- | Demo: Error handling
errorDemo :: Asyncio String
errorDemo = do
  _ <- Asyncio.liftEffect (log "Starting error demo...")

  result <- Asyncio.catchError
    (do
      _ <- Asyncio.liftEffect (log "About to throw...")
      Asyncio.throwError "Something went wrong!"
    )
    (\err -> do
      _ <- Asyncio.liftEffect (log $ "Caught error: " <> err)
      pure "Recovered!"
    )

  pure result

-- | Main entry point
main :: Effect Unit
main = Asyncio.run_ do
  _ <- Asyncio.liftEffect (log "=== Asyncio Demo ===\n")

  -- Sequential
  seq <- sequentialDemo
  _ <- Asyncio.liftEffect (log $ "Sequential result: " <> seq <> "\n")

  -- Concurrent
  conc <- concurrentDemo
  _ <- Asyncio.liftEffect (log $ "Concurrent result: " <> conc <> "\n")

  -- Parallel
  par <- parallelDemo
  _ <- Asyncio.liftEffect (log "Parallel result: done\n")

  -- Race
  winner <- raceDemo
  _ <- Asyncio.liftEffect (log $ "Race result: " <> winner <> "\n")

  -- Error handling
  recovered <- errorDemo
  _ <- Asyncio.liftEffect (log $ "Error result: " <> recovered <> "\n")

  _ <- Asyncio.liftEffect (log "=== All demos complete! ===")
  pure unit
