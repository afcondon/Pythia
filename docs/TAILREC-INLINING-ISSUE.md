# tailRec Inlining Issue - SOLVED

## Problem

The `purescript-backend-optimizer` inlines `tailRec` from `Control.Monad.Rec.Class`. The PureScript implementation uses recursion:

```purescript
tailRec :: forall a b. (a -> Step a b) -> a -> b
tailRec f = go
  where
  go a = case f a of
    Loop a' -> go a'
    Done b -> b
```

When inlined into Python, this produces direct recursive calls:

```python
(_v4_0 := (lambda step: (_v4_0)(f(step[1])) if step[0] == "Loop" else step[1]))
```

Python's default recursion limit is ~1000, so deep structures cause `RecursionError`.

## Solution

Use optimizer **directives** to prevent inlining, combined with a stack-safe runtime implementation.

### 1. Add Directives in Main.purs

```purescript
import PureScript.Backend.Optimizer.Directives (parseDirectiveFile)
import PureScript.Backend.Optimizer.Directives.Defaults (defaultDirectives)

-- In compile function:
let pythonDirectives = defaultDirectives <> """
  Control.Monad.Rec.Class.tailRec never
  Control.Monad.Rec.Class.tailRecM never
  Control.Monad.Rec.Class.tailRec2 never
  Control.Monad.Rec.Class.tailRec3 never
  """
let { directives } = parseDirectiveFile pythonDirectives

-- Use in buildModules:
, directives  -- instead of Map.empty
```

### 2. Stack-safe Runtime Implementation (in Builder.purs)

```python
def tailRec(f):
    def run(initial):
        result = f(initial)
        while result[0] == 'Loop':
            result = f(result[1])
        return result[1]
    return run
```

### 3. Result

Successfully tested with **50,000 elements** in a BST:
- Insert, size, height, member, findMin, findMax all work
- No stack overflow
- Tree height 34 (properly balanced with random insertion)

## Related Fixes Made

During investigation, also fixed:

1. `Convert.purs` LetRec - was using `toPyIdent` instead of `localIdent`, causing name mismatches
2. `Builder.purs` unconsImpl - needed to call `empty(None)` not just return `empty`
3. `Builder.purs` foldlArray - changed from recursive to iterative

## Date

2026-01-01
