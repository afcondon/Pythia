-- | Compile-time canary for FFI signature verification
-- |
-- | This module assigns FFI-provided functions to explicitly typed bindings.
-- | If upstream PureScript libraries change function signatures, this module
-- | will fail to compile, alerting us to update the Python runtime.
-- |
-- | The Python backend provides custom implementations for these functions
-- | (typically for performance or to avoid Python's recursion limit).
-- | This canary ensures our implementations stay in sync with expected types.
module Test.FFICanary where

import Prelude

import Control.Monad.Asyncio as Asyncio
import Control.Monad.Asyncio (Asyncio, Task)
import Control.Monad.Rec.Class (Step(..), tailRec)
import Control.Monad.ST.Internal as ST
import Data.Array as Array
import Data.Array.ST as STArray
import Data.Either (Either)
import Data.Foldable (foldl, foldr)
import Data.Maybe (Maybe)
import Data.Traversable (traverse)
import Effect (Effect)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Partial.Unsafe (unsafePartial)
import Unsafe.Coerce (unsafeCoerce)

--------------------------------------------------------------------------------
-- Control.Monad.Rec.Class
-- Critical for stack-safe recursion in Python
--------------------------------------------------------------------------------

tailRecCanary :: forall a b. (a -> Step a b) -> a -> b
tailRecCanary = tailRec

-- Step constructors
loopCanary :: forall a b. a -> Step a b
loopCanary = Loop

doneCanary :: forall a b. b -> Step a b
doneCanary = Done

--------------------------------------------------------------------------------
-- Data.Array
-- Many array functions have custom Python implementations
--------------------------------------------------------------------------------

unconsCanary :: forall a. Array a -> Maybe { head :: a, tail :: Array a }
unconsCanary = Array.uncons

consCanary :: forall a. a -> Array a -> Array a
consCanary = Array.cons

snocCanary :: forall a. Array a -> a -> Array a
snocCanary = Array.snoc

lengthCanary :: forall a. Array a -> Int
lengthCanary = Array.length

indexCanary :: forall a. Array a -> Int -> Maybe a
indexCanary = Array.index

concatCanary :: forall a. Array (Array a) -> Array a
concatCanary = Array.concat

filterCanary :: forall a. (a -> Boolean) -> Array a -> Array a
filterCanary = Array.filter

reverseCanary :: forall a. Array a -> Array a
reverseCanary = Array.reverse

takeCanary :: forall a. Int -> Array a -> Array a
takeCanary = Array.take

dropCanary :: forall a. Int -> Array a -> Array a
dropCanary = Array.drop

sliceCanary :: Int -> Int -> forall a. Array a -> Array a
sliceCanary = Array.slice

zipWithCanary :: forall a b c. (a -> b -> c) -> Array a -> Array b -> Array c
zipWithCanary = Array.zipWith

rangeCanary :: Int -> Int -> Array Int
rangeCanary = Array.range

replicateCanary :: forall a. Int -> a -> Array a
replicateCanary = Array.replicate

--------------------------------------------------------------------------------
-- Data.Foldable (Array instances)
-- foldl/foldr are iterative in Python to avoid stack overflow
--------------------------------------------------------------------------------

foldlArrayCanary :: forall a b. (b -> a -> b) -> b -> Array a -> b
foldlArrayCanary = foldl

foldrArrayCanary :: forall a b. (a -> b -> b) -> b -> Array a -> b
foldrArrayCanary = foldr

--------------------------------------------------------------------------------
-- Data.Traversable
--------------------------------------------------------------------------------

traverseArrayCanary :: forall a b. (a -> Effect b) -> Array a -> Effect (Array b)
traverseArrayCanary = traverse

--------------------------------------------------------------------------------
-- Effect
--------------------------------------------------------------------------------

pureEffectCanary :: forall a. a -> Effect a
pureEffectCanary = pure

bindEffectCanary :: forall a b. Effect a -> (a -> Effect b) -> Effect b
bindEffectCanary = bind

--------------------------------------------------------------------------------
-- Effect.Ref
--------------------------------------------------------------------------------

newRefCanary :: forall a. a -> Effect (Ref.Ref a)
newRefCanary = Ref.new

readRefCanary :: forall a. Ref.Ref a -> Effect a
readRefCanary = Ref.read

writeRefCanary :: forall a. a -> Ref.Ref a -> Effect Unit
writeRefCanary = Ref.write

modifyRefCanary :: forall a. (a -> a) -> Ref.Ref a -> Effect a
modifyRefCanary = Ref.modify

--------------------------------------------------------------------------------
-- Effect.Unsafe
--------------------------------------------------------------------------------

unsafePerformEffectCanary :: forall a. Effect a -> a
unsafePerformEffectCanary = unsafePerformEffect

--------------------------------------------------------------------------------
-- Control.Monad.ST.Internal
--------------------------------------------------------------------------------

stPureCanary :: forall r a. a -> ST.ST r a
stPureCanary = pure

stBindCanary :: forall r a b. ST.ST r a -> (a -> ST.ST r b) -> ST.ST r b
stBindCanary = bind

stRunCanary :: forall a. (forall r. ST.ST r a) -> a
stRunCanary = ST.run

--------------------------------------------------------------------------------
-- Partial.Unsafe
--------------------------------------------------------------------------------

unsafePartialCanary :: forall a. (Partial => a) -> a
unsafePartialCanary = unsafePartial

--------------------------------------------------------------------------------
-- Unsafe.Coerce
--------------------------------------------------------------------------------

unsafeCoerceCanary :: forall a b. a -> b
unsafeCoerceCanary = unsafeCoerce

--------------------------------------------------------------------------------
-- Data.Array.ST
--------------------------------------------------------------------------------

freezeCanary :: forall r a. STArray.STArray r a -> ST.ST r (Array a)
freezeCanary = STArray.freeze

thawCanary :: forall r a. Array a -> ST.ST r (STArray.STArray r a)
thawCanary = STArray.thaw

peekCanary :: forall r a. Int -> STArray.STArray r a -> ST.ST r (Maybe a)
peekCanary = STArray.peek

pokeCanary :: forall r a. Int -> a -> STArray.STArray r a -> ST.ST r Boolean
pokeCanary = STArray.poke

pushCanary :: forall r a. a -> STArray.STArray r a -> ST.ST r Int
pushCanary = STArray.push

popCanary :: forall r a. STArray.STArray r a -> ST.ST r (Maybe a)
popCanary = STArray.pop

--------------------------------------------------------------------------------
-- Control.Monad.Asyncio
-- Native Python async monad
--------------------------------------------------------------------------------

asyncioRunCanary :: forall a. Asyncio a -> Effect a
asyncioRunCanary = Asyncio.run

asyncioSleepCanary :: Number -> Asyncio Unit
asyncioSleepCanary = Asyncio.sleep

asyncioForkCanary :: forall a. Asyncio a -> Asyncio (Task a)
asyncioForkCanary = Asyncio.fork

asyncioAwaitCanary :: forall a. Task a -> Asyncio a
asyncioAwaitCanary = Asyncio.await

asyncioCancelCanary :: forall a. Task a -> Asyncio Unit
asyncioCancelCanary = Asyncio.cancel

asyncioRaceCanary :: forall a. Asyncio a -> Asyncio a -> Asyncio a
asyncioRaceCanary = Asyncio.race

asyncioAttemptCanary :: forall a. Asyncio a -> Asyncio (Either String a)
asyncioAttemptCanary = Asyncio.attempt

asyncioThrowErrorCanary :: forall a. String -> Asyncio a
asyncioThrowErrorCanary = Asyncio.throwError

asyncioCatchErrorCanary :: forall a. Asyncio a -> (String -> Asyncio a) -> Asyncio a
asyncioCatchErrorCanary = Asyncio.catchError

asyncioBracketCanary :: forall a b. Asyncio a -> (a -> Asyncio Unit) -> (a -> Asyncio b) -> Asyncio b
asyncioBracketCanary = Asyncio.bracket

asyncioLiftEffectCanary :: forall a. Effect a -> Asyncio a
asyncioLiftEffectCanary = Asyncio.liftEffect
