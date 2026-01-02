# Aff to Python asyncio Design

## Overview

Map PureScript's `Aff` monad to Python's `asyncio` in a principled way.

## Core Insight

Both Aff and asyncio are:
- Cooperative (not preemptive)
- Single-threaded by default
- Support cancellation
- "Colored" (async code must be called from async context)

## Representation

### Option A: Coroutine-based (Recommended)

```python
# Aff a  →  Callable[[], Coroutine[Any, Any, a]]
# A thunk that returns a coroutine (lazy, like Aff)

# Example: Aff String
aff_value = lambda: some_async_operation()
```

The thunk preserves laziness - the coroutine isn't created until run.

### Option B: Continuation-based (Faithful to JS)

```python
# Aff a  →  Callable[[Callable[[Exception], None], Callable[[a], None]], Canceler]
# CPS with error callback, success callback, returns canceler

def my_aff(on_error, on_success):
    # ... do async work ...
    return canceler
```

More complex, less Pythonic, but closer to original semantics.

## Recommended: Option A with asyncio

### Core Types

```purescript
-- In PureScript (existing)
foreign import data Aff :: Type -> Type

-- Fiber is a running computation
foreign import data Fiber :: Type -> Type
```

### Python Runtime Implementation

```python
import asyncio
from typing import TypeVar, Callable, Coroutine, Any, Optional

A = TypeVar('A')
B = TypeVar('B')

# Aff a = () -> Coroutine[Any, Any, a]
# Fiber a = asyncio.Task[a]

# Pure: lift a value into Aff
def pureAff(a):
    async def coro():
        return a
    return lambda: coro()

# Bind: sequence Aff computations
def bindAff(aff_a):
    def bind_k(f):
        async def coro():
            a = await aff_a()
            aff_b = f(a)
            return await aff_b()
        return lambda: coro()
    return bind_k

# Lift Effect into Aff
def liftEffect(eff):
    async def coro():
        return eff()  # Effect is () -> a
    return lambda: coro()

# Launch: run Aff to completion (blocking)
def launchAff_(aff):
    def effect():
        asyncio.run(aff())
    return effect

# Fork: run Aff in background, get Fiber
def forkAff(aff):
    async def coro():
        loop = asyncio.get_event_loop()
        task = loop.create_task(aff())
        return task  # Task is our Fiber
    return lambda: coro()

# Join: wait for Fiber to complete
def joinFiber(fiber):
    async def coro():
        return await fiber
    return lambda: coro()

# Kill: cancel a Fiber
def killFiber(error):
    def kill(fiber):
        async def coro():
            fiber.cancel()
            try:
                await fiber
            except asyncio.CancelledError:
                pass
        return lambda: coro()
    return kill

# Delay
def delay(ms):
    async def coro():
        await asyncio.sleep(ms / 1000.0)
    return lambda: coro()

# Parallel: run multiple Affs concurrently
def parallel(affs):
    async def coro():
        coros = [aff() for aff in affs]
        return await asyncio.gather(*coros)
    return lambda: coro()

# Try/catch for Aff
def catchError(handler):
    def catch(aff):
        async def coro():
            try:
                return await aff()
            except Exception as e:
                recovery_aff = handler(e)
                return await recovery_aff()
        return lambda: coro()
    return catch

# Throw error in Aff
def throwError(error):
    async def coro():
        raise error
    return lambda: coro()

# Bracket for resource safety
def bracket(acquire):
    def with_release(release):
        def use(use_fn):
            async def coro():
                resource = await acquire()
                try:
                    result = await use_fn(resource)()
                    return result
                finally:
                    await release(resource)()
            return lambda: coro()
        return use
    return with_release
```

### Example Usage (PureScript)

```purescript
module Example where

import Prelude
import Effect.Aff (Aff, delay, forkAff, joinFiber, launchAff_)
import Effect.Class.Console (log)

main :: Effect Unit
main = launchAff_ do
  log "Starting..."

  -- Fork two parallel tasks
  fiber1 <- forkAff do
    delay (Milliseconds 1000.0)
    pure "Task 1 done"

  fiber2 <- forkAff do
    delay (Milliseconds 500.0)
    pure "Task 2 done"

  -- Wait for both
  result1 <- joinFiber fiber1
  result2 <- joinFiber fiber2

  log result1
  log result2
```

### Generated Python

```python
def main():
    return launchAff_(
        bindAff(log("Starting..."))(lambda _:
        bindAff(forkAff(
            bindAff(delay(1000.0))(lambda _:
            pureAff("Task 1 done"))
        ))(lambda fiber1:
        bindAff(forkAff(
            bindAff(delay(500.0))(lambda _:
            pureAff("Task 2 done"))
        ))(lambda fiber2:
        bindAff(joinFiber(fiber1))(lambda result1:
        bindAff(joinFiber(fiber2))(lambda result2:
        bindAff(log(result1))(lambda _:
        log(result2)
        ))))))
    )
```

## Integration with Effect

The key relationship:
- `Effect a` = `() -> a` (synchronous)
- `Aff a` = `() -> Coroutine[Any, Any, a]` (asynchronous)

`liftEffect` bridges them:
```python
def liftEffect(eff):
    async def coro():
        return eff()
    return lambda: coro()
```

## Challenges

### 1. Event Loop Management

Python's asyncio requires an event loop. Options:
- `launchAff_` creates one via `asyncio.run()`
- For nested async, use `asyncio.get_event_loop().run_until_complete()`

### 2. Colored Functions

Async functions can only be awaited from async context. This maps well to
Aff's type separation, but means we can't freely mix Effect and Aff.

### 3. Cancellation Semantics

asyncio cancellation raises `CancelledError`. We need to handle this
gracefully and map it to Aff's cancellation model.

### 4. Error Types

Aff has typed errors; Python exceptions are untyped. We could:
- Use a wrapper exception class
- Store error type information in the exception

## Implementation Plan

1. Add Aff FFI functions to `runtimeProvidedForeign`
2. Implement core functions in Builder.purs runtime generation
3. Add `never` directives for Aff functions that shouldn't be inlined
4. Create FFI canary for Aff signatures
5. Build test cases with concurrent operations

## Alternative: purescript-aff-asyncio

Could also create a separate library `purescript-aff-asyncio` that provides
a Python-native async monad, distinct from `Aff`. This avoids trying to
perfectly replicate Aff semantics and embraces Python's model directly.

```purescript
module Control.Monad.Asyncio where

foreign import data Asyncio :: Type -> Type

instance monadAsyncio :: Monad Asyncio
instance monadEffectAsyncio :: MonadEffect Asyncio

foreign import run :: forall a. Asyncio a -> Effect a
foreign import fork :: forall a. Asyncio a -> Asyncio (Task a)
foreign import await :: forall a. Task a -> Asyncio a
foreign import sleep :: Number -> Asyncio Unit
```

This might be cleaner than trying to perfectly emulate Aff.
