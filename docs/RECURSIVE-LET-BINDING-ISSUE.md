# Recursive local bindings miscompiled — `Data.Map` was unusable

**Status:** FIXED 2026-07-30 (found the same day)
**Severity when open:** blocking — `ordered-collections` could not be imported
**Found by:** the Grid Explorer rebuild (`examples/grid-explorer`), the first
code in this repo to use `Data.Map` / `Data.Set`

## Symptom

Any module that transitively imported `Data.Map` failed at **import time**:

```
File "output-py/Data_Map_Internal.py", line 227, in <lambda>
  def _lam106(f, z): return (lambda: ((go := (Data_Function_Uncurried.mkFn2)(_mk(_lam104, f, go))), _mk(_lam105, go, z))[-1])()
                                                                                             ^^
UnboundLocalError: cannot access local variable 'go' where it is not associated with a value
```

Nothing needed to *call* the offending function; the module-level binding is
evaluated on import, so the whole program died before `main` ran.

## Cause

A self-recursive local binding — `foldrWithIndex` in `Data.Map.Internal`,
whose `where`-bound `go` refers to itself:

```purescript
foldrWithIndex f z m = runFn2 go m z
  where
  go = mkFn2 \m' z' -> case m' of
    Leaf -> z'
    Node _ _ k v l r -> runFn2 go l (f k v (runFn2 go r z'))
```

Lambda lifting captures free variables **by value**, at the moment the closure
is built: `_mk(_lam104, f, go)` reads `go` eagerly to build the environment. On
the right-hand side of `go`'s own binding it is not bound yet, and cannot be —
value capture cannot tie that knot.

The backend already knew this in principle. Its header comment said recursive
local bindings "keep their outermost lambda chain inline" so the name resolves
at call time. The implementation checked for a literal `Abs` at the root of the
right-hand side — and `mkFn2 \m' z' -> …` is an `App`, so the lambda underneath
was lifted like any other, with `go` eagerly captured. The check was one level
too shallow.

## The exact trigger (narrower than it first looked)

Recursion alone was fine. What mattered was **how the self-reference reached
the body**, which depends on whether the body gets lambda-lifted:

| shape | self-reference becomes | result |
|---|---|---|
| top-level | a module-global name | fine — late-bound |
| local, tail-recursive | nothing; TCO rewrites it to a loop | fine |
| local, non-tail, root is a bare `Abs` | a free variable in an inline closure | fine — late-bound |
| local, non-tail, `Abs` **under a wrapper** | an eager `_mk` argument | **broke** |

Only the last row failed. A container fold written with `mkFn2` lands exactly
there, which is why `Data.Map.Internal.foldrWithIndex` found it.

## Why it went unnoticed

Two independent gaps, and the second is the more interesting one.

**No corpus module had ever imported `ordered-collections`** — verified by grep
across `examples/*/src`, `examples/*/spago.yaml`, `test-project/src` and
`test-suite/`. `Data.Map` and `Data.Set` were simply never compiled, on any
backend.

**And `Test.Recursion` passed.** The corpus did have recursion coverage, and it
was green, because every case in it is either top-level or tail-recursive —
rows 1 and 2 of the table above. `triangle`'s `where`-bound `go` looks like the
failing shape and is not: purepy's TCO transform rewrites it to a `_tco_run`
loop, so `go` never appears on its own right-hand side at all.

That is the lesson worth keeping: the feature was covered, the *codegen path*
was not. Coverage counted by language concept ("we test recursion") missed a
variant that compiles completely differently.

The bug had been latent since the backend was written. It was not a regression.

## The fix

`src/Language/PureScript/Python/CodeGen.hs`. The codegen state gained a **LATE
set** — names whose binding is not complete yet, so any reference to them must
resolve at call time rather than at closure-creation time.

- Compiling a recursive `let` group puts the group's own names in the LATE set
  for the whole of each right-hand side, wherever the lambda sits in it.
- `liftAbs` refuses to lift a lambda whose captured environment would include a
  LATE name, emitting it inline instead. Python resolves an enclosing-scope
  name at call time, which is precisely the late binding the knot needs.
- Entering an inline lambda body **clears** the LATE set, because that body
  only runs when the lambda is called, by which point the binding is complete.
  So lifting resumes immediately inside, and the deep nesting that lifting
  exists to avoid stays confined to the lambda chain itself.
- One exception: a lambda in application-head position is invoked immediately,
  so its body runs *before* the binding completes. That case keeps the LATE
  set (`inlineAbsKeepLate`).

The result for the failing shape:

```python
# before — `go` read while building the closure
(go := mkFn2(_mk(_lam0, go)))

# after — `_mk` runs only once `node` is supplied, by which time `go` is bound
(go := mkFn2((lambda node: _mk(_lam0, go, node))))
```

The LATE set is carried in the `State` rather than as a parameter, so the dozen
mutually-recursive generators keep their signatures.

**Sibling backends are structurally immune** and needed no change: Jurist
declares recursive locals with Julia's `local` and Gnomon with Go's `var`, both
declare-then-assign with capture by reference. Neither lambda-lifts, because
neither has CPython's ~200-deep paren-nesting limit forcing it.

## Verification

- `test-suite/src/Test/RecursiveBindings.purs` — all four shapes above.
  `sumTree` returns 6, matching Node; it raised `UnboundLocalError` before.
- `test-suite/src/Test/OrderedCollections.purs` — **new**, 40 assertions over
  `Data.Map` and `Data.Set`: ordered traversal, indexed folds, insert/delete/
  alter/update, union/intersection/difference, and a 32-entry map big enough to
  have been rebalanced. All byte-identical to the JS reference.
- Both were also missing from `run_tests.py`'s `TEST_MODULES`, so neither ran
  in the suite until they were added — the earlier claim that the corpus was
  "red on one case" was only ever true when run by hand.
- Corpus: **465/469 identical, 4 known divergences, 0 failures** (was 422/426).
- `examples/grid-explorer/core/src/Grid/Graph.purs` is back on `Map Int
  (Set Int)` instead of the sorted-array workaround, and the service returns
  the same figures it did before: 4 critical / 8 warning / 29 safe under N-1,
  cascade depth 2 from line 35, 7 lines lost, 11.55 MW shed.

## Related

`docs/TAILREC-INLINING-ISSUE.md` — a different codegen issue, same family:
correct PureScript that the Python emitter mistranslates rather than rejects.
