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

## The exact trigger (narrower than it first looks)

Recursion alone is fine. What matters is **how the self-reference reaches the
body**, and that depends on whether the body gets lambda-lifted:

| shape | self-reference becomes | result |
|---|---|---|
| top-level | a module-global name | fine — late-bound |
| local, tail-recursive | nothing; TCO rewrites it to a loop | fine |
| local, non-tail, body inline | a free variable in a closure | fine — late-bound |
| local, non-tail, **body lifted** | an eager `_mk` argument | **breaks** |

Only the last row fails. Confirmed by
`test-suite/src/Test/RecursiveBindings.purs`, which holds all four shapes:

```
                node (reference)   Pythia
  factLocal     120                120                    inline closure
  sumTree       6                  UnboundLocalError      lifted body
  evenOddLocal  true               True                   mutual, inline
```

A body gets lifted once it is complex enough — an uncurried `mkFn2` lambda
with a constructor `case` is plenty. That is the ordinary way to write a
container fold, which is exactly why `Data.Map.Internal.foldrWithIndex` lands
on it.

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

The bug has been latent since the backend was written. It is not a regression.

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

The corpus now carries it as a permanent case:

```bash
cd test-suite
spago build && stack exec --stack-yaml ../stack.yaml purepy -- output output-py
cd output-py && python3 -c "import sys; sys.path.insert(0,'.'); \
  import Test_RecursiveBindings as T; print(T.sumTree(T.sample))"
# UnboundLocalError: cannot access local variable 'go'
node -e "console.log(require('./output/Test.RecursiveBindings/index.js').sumTree(...))"  # 6
```

Or via any real use — adding `ordered-collections` and `import Data.Map as Map`
to any example kills it at import time, before `main` runs.

## Workaround in force

`examples/grid-explorer/core/src/Grid/Graph.purs` avoids `Data.Map` and
`Data.Set` entirely, using sorted arrays and linear scans instead. On a
thirty-bus network the asymptotics are irrelevant, but the module is written
against a worse interface than it wants, and says so at the top. It should go
back to `Data.Map` once this is fixed.

## Related

`docs/TAILREC-INLINING-ISSUE.md` — a different codegen issue, same family:
correct PureScript that the Python emitter mistranslates rather than rejects.
