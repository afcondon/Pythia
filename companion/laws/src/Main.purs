-- | Laws for `Python.Kwargs`.
-- |
-- | This lane exists because the differential corpus **structurally cannot**
-- | cover a companion library: its method is running the same FFI-free source
-- | on two backends and diffing byte-for-byte, and `Python.Kwargs` has no
-- | JavaScript counterpart to diff against. Absent this file, "we have a
-- | conformance suite" would imply a coverage it does not have.
-- |
-- | So the assertions here are of the kind you *can* make against a single
-- | runtime: round-trips, omissions, orderings, and — the one that actually
-- | matters — that the dict really does splat into a Python call.
module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Effect.Ref as Ref
import Python.Kwargs (Kwargs, debugKwargs, kwargs, noKwargs)

-- | A Python function that accepts arbitrary keyword arguments and reports
-- | what it received, sorted. This is the real test: everything else checks
-- | the dict we built, this checks that Python accepts it as `**kwargs`.
foreign import probeImpl :: Kwargs -> String

-- | Same, but for a function with FIXED named parameters and no `**kwargs`,
-- | which is what a real library entry point looks like. Passing an unknown
-- | key here is a `TypeError` at call time.
foreign import fixedArityImpl :: Kwargs -> String

check :: Ref.Ref Int -> String -> String -> String -> Effect Unit
check failures label expected actual =
  if expected == actual then log ("ok   " <> label)
  else do
    _ <- Ref.modify (_ + 1) failures
    log ("FAIL " <> label <> "\n       expected " <> expected
         <> "\n       actual   " <> actual)

main :: Effect Unit
main = do
  failures <- Ref.new 0
  let t = check failures

  -- empty
  t "empty record" "{}" (debugKwargs (kwargs {}))
  t "noKwargs" "{}" (debugKwargs noKwargs)

  -- the scalar types the contract admits, in their Python representations
  t "string" "{name='nr'}" (debugKwargs (kwargs { name: "nr" }))
  t "int" "{n=20}" (debugKwargs (kwargs { n: 20 }))
  t "number" "{tol=1e-08}" (debugKwargs (kwargs { tol: 1.0e-8 }))
  t "boolean-true" "{flag=True}" (debugKwargs (kwargs { flag: true }))
  t "boolean-false" "{flag=False}" (debugKwargs (kwargs { flag: false }))

  -- PureScript Boolean must arrive as a Python bool, not a string or an int:
  -- `f(check=True)` and `f(check=1)` are different calls to many libraries.
  t "boolean-is-python-bool" "True" (probeImpl (kwargs { only: true }))

  -- arrays are lists; element type is checked by ToPy
  t "array-int" "{xs=[1, 2, 3]}" (debugKwargs (kwargs { xs: [ 1, 2, 3 ] }))
  t "array-string" "{xs=['a', 'b']}" (debugKwargs (kwargs { xs: [ "a", "b" ] }))
  t "array-empty" "{xs=[]}" (debugKwargs (kwargs { xs: [] :: Array Int }))

  -- nested records become nested dicts
  t "nested" "{opts={'depth': 2}}" (debugKwargs (kwargs { opts: { depth: 2 } }))

  -- THE distinguishing property: Nothing OMITS, it does not pass None.
  t "maybe-just" "{tol=0.01}" (debugKwargs (kwargs { tol: Just 0.01 }))
  t "maybe-nothing" "{}" (debugKwargs (kwargs { tol: Nothing :: Maybe Number }))
  t "maybe-mixed" "{algorithm='nr', n=5}"
    (debugKwargs (kwargs { algorithm: Just "nr", n: 5, tol: Nothing :: Maybe Number }))

  -- ordering is by label, so the rendering is deterministic
  t "sorted-by-label" "{a=1, b=2, c=3}" (debugKwargs (kwargs { c: 3, a: 1, b: 2 }))

  -- and the point of the whole exercise: it splats
  t "splat-into-kwargs" "algorithm='nr'|max_iteration=20"
    (probeImpl (kwargs { algorithm: "nr", max_iteration: 20 }))
  t "splat-empty" "" (probeImpl noKwargs)

  -- a fixed-arity target: supplying a subset is fine, and an omitted Maybe
  -- really is absent rather than an explicit None
  t "fixed-arity-subset" "algorithm=nr init=flat" (fixedArityImpl (kwargs { algorithm: "nr" }))
  t "fixed-arity-omitted-is-default" "algorithm=nr init=flat"
    (fixedArityImpl (kwargs { algorithm: "nr", init: Nothing :: Maybe String }))
  t "fixed-arity-supplied" "algorithm=nr init=dc"
    (fixedArityImpl (kwargs { algorithm: "nr", init: Just "dc" }))

  n <- Ref.read failures
  log ""
  if n == 0 then log "ALL LAWS HOLD"
  else log (show n <> " LAW FAILURES")
