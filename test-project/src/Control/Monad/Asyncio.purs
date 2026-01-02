-- | Native Python asyncio monad for asynchronous programming.
-- |
-- | This module provides a principled async monad that maps directly to
-- | Python's asyncio, rather than emulating PureScript's Aff semantics.
-- |
-- | Key types:
-- | - `Asyncio a` - An async computation that produces `a`
-- | - `Task a` - A running async computation (like a Fiber)
-- |
-- | Example:
-- | ```purescript
-- | main :: Effect Unit
-- | main = Asyncio.run do
-- |   log "Starting..."
-- |   task1 <- Asyncio.fork do
-- |     Asyncio.sleep 1000.0
-- |     pure "Task 1 done"
-- |   task2 <- Asyncio.fork do
-- |     Asyncio.sleep 500.0
-- |     pure "Task 2 done"
-- |   result1 <- Asyncio.await task1
-- |   result2 <- Asyncio.await task2
-- |   log result1
-- |   log result2
-- | ```
module Control.Monad.Asyncio
  ( Asyncio
  , Task
  -- Running
  , run
  , run_
  -- Core operations
  , sleep
  , fork
  , await
  , cancel
  -- Parallelism
  , parallel
  , parallelImpl
  , race
  -- Error handling
  , attempt
  , throwError
  , catchError
  -- Resource management
  , bracket
  -- Lifting
  , liftEffect
  -- Typeclass instances are defined below
  ) where

import Prelude

import Data.Either (Either)
import Data.Traversable (class Traversable, traverse)
import Effect (Effect)

-- | An asynchronous computation that produces a value of type `a`.
-- | This maps to a Python coroutine thunk: `() -> Coroutine[Any, Any, a]`
foreign import data Asyncio :: Type -> Type

-- | A running asynchronous task that will produce a value of type `a`.
-- | This maps to a Python `asyncio.Task`.
foreign import data Task :: Type -> Type

--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

foreign import pureAsyncio :: forall a. a -> Asyncio a
foreign import bindAsyncio :: forall a b. Asyncio a -> (a -> Asyncio b) -> Asyncio b
foreign import mapAsyncio :: forall a b. (a -> b) -> Asyncio a -> Asyncio b
foreign import applyAsyncio :: forall a b. Asyncio (a -> b) -> Asyncio a -> Asyncio b

-- FFI function aliases (internal names differ from exported names)
foreign import runAsyncio :: forall a. Asyncio a -> Effect a
foreign import forkAsyncio :: forall a. Asyncio a -> Asyncio (Task a)
foreign import awaitTask :: forall a. Task a -> Asyncio a
foreign import cancelTask :: forall a. Task a -> Asyncio Unit
foreign import raceAsyncio :: forall a. Asyncio a -> Asyncio a -> Asyncio a
foreign import attemptAsyncio :: forall a. Asyncio a -> Asyncio (Either String a)
foreign import throwErrorAsyncio :: forall a. String -> Asyncio a
foreign import catchErrorAsyncio :: forall a. Asyncio a -> (String -> Asyncio a) -> Asyncio a
foreign import bracketAsyncio :: forall a b. Asyncio a -> (a -> Asyncio Unit) -> (a -> Asyncio b) -> Asyncio b
foreign import liftEffectAsyncio :: forall a. Effect a -> Asyncio a

instance Functor Asyncio where
  map = mapAsyncio

instance Apply Asyncio where
  apply = applyAsyncio

instance Applicative Asyncio where
  pure = pureAsyncio

instance Bind Asyncio where
  bind = bindAsyncio

instance Monad Asyncio

--------------------------------------------------------------------------------
-- Running
--------------------------------------------------------------------------------

-- | Run an async computation to completion, blocking until done.
-- | This creates a Python event loop and runs the coroutine.
run :: forall a. Asyncio a -> Effect a
run = runAsyncio

-- | Run an async computation, discarding the result.
run_ :: forall a. Asyncio a -> Effect Unit
run_ asyncio = void (run asyncio)

--------------------------------------------------------------------------------
-- Core Operations
--------------------------------------------------------------------------------

-- | Sleep for the given number of milliseconds.
foreign import sleep :: Number -> Asyncio Unit

-- | Fork an async computation to run concurrently, returning a Task handle.
fork :: forall a. Asyncio a -> Asyncio (Task a)
fork = forkAsyncio

-- | Wait for a Task to complete and get its result.
await :: forall a. Task a -> Asyncio a
await = awaitTask

-- | Cancel a running Task.
cancel :: forall a. Task a -> Asyncio Unit
cancel = cancelTask

--------------------------------------------------------------------------------
-- Parallelism
--------------------------------------------------------------------------------

-- | Run multiple async computations in parallel, collecting all results.
-- | All computations run concurrently; waits for all to complete.
foreign import parallelImpl :: forall a. Array (Asyncio a) -> Asyncio (Array a)

-- | Run multiple async computations in parallel.
parallel :: forall t a. Traversable t => t (Asyncio a) -> Asyncio (t a)
parallel = traverse identity

-- | Run two async computations, returning the result of whichever finishes first.
-- | The other computation is cancelled.
race :: forall a. Asyncio a -> Asyncio a -> Asyncio a
race = raceAsyncio

--------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------

-- | Attempt an async computation, catching any errors.
attempt :: forall a. Asyncio a -> Asyncio (Either String a)
attempt = attemptAsyncio

-- | Throw an error in the async context.
throwError :: forall a. String -> Asyncio a
throwError = throwErrorAsyncio

-- | Catch errors and recover with a handler.
catchError :: forall a. Asyncio a -> (String -> Asyncio a) -> Asyncio a
catchError = catchErrorAsyncio

--------------------------------------------------------------------------------
-- Resource Management
--------------------------------------------------------------------------------

-- | Acquire a resource, use it, and release it safely.
-- | The release action runs even if the use action throws.
bracket
  :: forall a b
   . Asyncio a           -- ^ Acquire
  -> (a -> Asyncio Unit) -- ^ Release
  -> (a -> Asyncio b)    -- ^ Use
  -> Asyncio b
bracket = bracketAsyncio

--------------------------------------------------------------------------------
-- Lifting
--------------------------------------------------------------------------------

-- | Lift a synchronous Effect into Asyncio.
liftEffect :: forall a. Effect a -> Asyncio a
liftEffect = liftEffectAsyncio
