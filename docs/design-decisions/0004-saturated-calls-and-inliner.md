# 0004. Saturated calls and the purs inliner set

- Status: Accepted
- Date: 2026-10-27
- Supersedes: the curried-call part of [0002](0002-expression-emission-lambda-lifting.md)
  (and, for Pythia, of the representation it inherited from **Jurist**
  ADR-0001). A function *value* is still a curried unary closure.
- Cross-backend: review X1 (`purescript-backends/REVIEW-2026-10.md`), the same
  decision in Gnomon (its ADR-0009) and Jurist.

## Context

Every call was a curried spine, `(f)(a)(b)(c)`: one Python call, and one
closure built, per argument. The review measured `runFn4(mkFn4 f)` at 736 ns
against 31 ns direct, a curried constructor at 204 ns against 10 ns for a
tuple, and an `Array Number` fold at 76 ns per element curried against 6.8 as
a plain loop. So most of `seam-tax.md`'s "~104 ns per Number, structural" was
codegen (review P6, X11).

The objection recorded for both lanes was that `App f args` is a syntactic
spine, not a saturation guarantee. That is true for an unknown head. It is
false for a top-level binding defined as an n-deep lambda chain and applied to
at least n arguments, and purerl has always emitted `f/n` for that case.
`purepy` reads every module before emitting any, and `backend-py` collects
every module before it prunes, so the arity map is one fold.

Andrew's framing (brief `BRIEF-x1-saturated-calls.md`): if PureScript is a
thin layer over robust runtimes, optimising calls is worth an extra pass, and
where the JS world has a mechanism we should do the same or something
analogous.

## Decision

**Both lanes, saturated calls.** A top-level `f = \p1 .. pn -> body` emits
`def _ps_sat_f(p1, .., pn): return body` and `f` as a curried wrapper over it.
A self-tail-recursive one keeps its `_tco_run` loop, now entered from the
def. A call with k ≥ n arguments becomes `_ps_sat_f(a1, .., an)`, across
modules `_psmod_M._ps_sat_f(..)`, with the other k − n applied curried. A
binding in a lazily initialised recursive group is a thunk, not a def, and
stays curried.

**`purepy` only, the purs inliner set** (`CoreImp/Optimizer/Inliner.hs`).
`backend-py` already gets these from purescript-backend-optimizer's IR
(`UncurriedApp`, typed `PrimOp`s, `CtorSaturated`):

- `runFnN f a..` is `f(a..)`; `mkFnN (\a.. -> e)` is an n-ary def, lifted
  like any lambda (0002), `_mk` being `functools.partial`; `runEffectFnN` /
  `mkEffectFnN` and the `ST` forms likewise;
- primitive ops through a known dictionary as Python operators, looking
  through the module-level aliases CoreFn floats out
  (`negate = Data.Ring.negate ringNumber`), as purs's "expander" does;
  `div` on `Number` calls the runtime's `_num_div`, because Python raises on
  `x / 0.0`; `Data.Int.Bits` through the runtime's `_int32`;
- saturated constructors as tag-tuples (`("Just", x)`) or dicts, a newtype as
  its argument.

Each inlined op means what the `*_foreign.py` shim it bypasses means.

**Generated names.** The saturated defs live in `_ps_`, the namespace
`backend-py` already reserves. `purepy` did not escape it, so the two lanes
mangled an identifier beginning `_ps_` differently. `purepy` now escapes it
exactly as `backend-py` does (`_ps_x` → `_ps__x`), which the shared foreign
shims need anyway.

## Consequences

- NEGZERO is closed on both lanes: seven entries went STALE and were deleted
  with their cause. Three fixes did it: `negate` on `Number` is unary minus,
  as on JS; `backend-py` printed a folded `-0.0` literal through `show`,
  which gives `"0.0"`, and now writes `(-0.0)`; and the `Data.Number`
  `min`/`max` shims now order `-0.0` below `+0.0`, as `Math.min` does.
- The FFI convention is untouched: foreigns are not declarations, so they
  never enter the arity map and stay curried.
- Generated code is about 14 % larger. `purepy` and CPython's byte-compilation
  take about as long as before (numbers in the PR).
- Only top-level bindings are saturated. A local `let` function, and a call
  through an unknown dictionary, stay curried.
