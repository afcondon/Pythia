# Recursive local bindings miscompile — `Data.Map` is unusable

**Status:** open, found 2026-07-30
**Severity:** blocking — `ordered-collections` cannot be imported at all
**Found by:** the Grid Explorer rebuild (`examples/grid-explorer`), the first
code in this repo to use `Data.Map` / `Data.Set`

## Symptom

Any module that transitively imports `Data.Map` fails at **import time**:

```
File "output-py/Data_Map_Internal.py", line 227, in <lambda>
  def _lam106(f, z): return (lambda: ((go := (Data_Function_Uncurried.mkFn2)(_mk(_lam104, f, go))), _mk(_lam105, go, z))[-1])()
                                                                                             ^^
UnboundLocalError: cannot access local variable 'go' where it is not associated with a value
```

Nothing needs to *call* the offending function; the module-level binding is
evaluated on import, so the whole program dies before `main` runs.

## Cause

The PureScript is a self-recursive local binding — `foldrWithIndex` in
`Data.Map.Internal`, whose `where`-bound `go` refers to itself:

```purescript
foldrWithIndex f z m = runFn2 go m z
  where
  go = mkFn2 \m' z' -> case m' of
    Leaf -> z'
    Node _ _ k v l r -> runFn2 go l (f k v (runFn2 go r z'))
```

We emit that as a walrus assignment whose right-hand side captures `go` **by
value** through a partial application:

```python
(go := mkFn2(_mk(_lam104, f, go)))
#                            ^^^ read before the walrus has bound it
```

`_mk(_lam104, f, go)` evaluates `go` eagerly to build the closure environment,
so the name must already be bound. It isn't, and cannot be — this is a knot
that value-capture cannot tie.

## Why it went unnoticed

No example, test-project or corpus module in this repo had ever imported
`Data.Map`, `Data.Set` or `ordered-collections` — verified by grep across
`examples/*/src`, `examples/*/spago.yaml` and `test-project/src`. The bug has
been latent since the backend was written. It is not a regression.

## The shape of the fix

The generated environment capture is the problem, not the walrus. Python
closures over **enclosing-scope names** are late-bound, so a recursive local
binding wants to be emitted as a `def` that refers to the name freely, rather
than as a value-capturing partial application:

```python
# instead of:  (go := mkFn2(_mk(_lam104, f, go)))
def _rec_go(a, b):
    return _lam103(f, go, a, b)   # `go` resolved at CALL time — fine
go = mkFn2(_rec_go)
```

Any equivalent that defers the self-reference works — a one-element cell
patched after construction would too. What does not work is any scheme that
reads `go` while building the closure.

Detection is straightforward: a `Let` group whose binding refers to a name in
its own group. CoreFn already distinguishes recursive binding groups
(`Rec` vs `NonRec`), so the information is present and does not need
inferring.

## Reproduction

```bash
cd examples/<anything>
# add `ordered-collections` to spago.yaml dependencies, then in any module:
#   import Data.Map as Map
#   main = log (show (Map.size (Map.singleton 1 "a")))
spago build && stack exec --stack-yaml ../../stack.yaml purepy -- output output-py
python3 output-py     # UnboundLocalError before anything runs
```

## Workaround in force

`examples/grid-explorer/core/src/Grid/Graph.purs` avoids `Data.Map` and
`Data.Set` entirely, using sorted arrays and linear scans instead. On a
thirty-bus network the asymptotics are irrelevant, but the module is written
against a worse interface than it wants, and says so at the top. It should go
back to `Data.Map` once this is fixed.

## Related

`docs/TAILREC-INLINING-ISSUE.md` — a different codegen issue, same family:
correct PureScript that the Python emitter mistranslates rather than rejects.
