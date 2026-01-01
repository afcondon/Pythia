# PureScript Python Backend: Implementation Notes

This document describes the implementation of `purepy`, a PureScript-to-Python compiler, with particular focus on the challenges encountered and solutions developed. It also compares our approach with other PureScript backends (JavaScript, Erlang, Lua).

## Overview

The compiler reads CoreFn JSON (PureScript's intermediate representation) and generates Python source code. The approach is inspired by [purerl](https://github.com/purerl/purerl) (the Erlang backend).

## Key Challenges and Solutions

### 1. Mutually Recursive Bindings (The Lazy Thunk Pattern)

**Problem**: PureScript's typeclass dictionaries often form mutually recursive groups. For example, in the `Effect` module:

```purescript
-- These all reference each other!
monadEffect :: Monad Effect
bindEffect :: Bind Effect
applyEffect :: Apply Effect
applicativeEffect :: Applicative Effect
functorEffect :: Functor Effect
```

In JavaScript, this works because of variable hoisting - all `var` declarations are hoisted to the top of their scope, so forward references work. Python executes module-level code sequentially, causing `NameError` for forward references.

**Failed Approaches**:
1. Simple sequential assignment - fails because later bindings don't exist yet
2. Using the binding name directly in lambdas - captures undefined at definition time

**Solution**: We adopted the JavaScript backend's `$runtime_lazy` pattern, adapted for Python:

```python
# Runtime support
def _runtime_lazy(name, module_name, init):
    state = [0]  # 0=uninit, 1=initializing, 2=done
    val = [None]
    def thunk(*args):
        if state[0] == 2:
            return val[0]
        if state[0] == 1:
            raise RuntimeError(f'{name} was needed before finishing init')
        state[0] = 1
        val[0] = init()
        state[0] = 2
        return val[0]
    return thunk
```

For a Rec binding group, we generate:

```python
# 1. Define lazy thunks (these DON'T evaluate yet)
_lazy_monadEffect = _runtime_lazy("monadEffect", "Effect",
    lambda: {"Applicative0": lambda _: _lazy_applicativeEffect(), ...})
_lazy_applicativeEffect = _runtime_lazy("applicativeEffect", "Effect",
    lambda: {"Apply0": lambda _: _lazy_applyEffect(), ...})

# 2. Force thunks to create actual values
monadEffect = _lazy_monadEffect()
applicativeEffect = _lazy_applicativeEffect()
```

**Key insight**: Inside the Rec group's lambdas, we reference `_lazy_X()` (the thunk call), not `X` (which doesn't exist yet). This is different from JavaScript where hoisting makes `X` available (though undefined) at parse time.

**Comparison with other backends**:
- **JavaScript**: Uses `$runtime_lazy` but references the final binding name inside lambdas (works due to hoisting)
- **Erlang**: No issue - Erlang functions can reference other functions that are defined later in the module
- **Lua**: Similar to JavaScript, uses lazy initialization

### 2. Python Reserved Word Collisions

**Problem**: PureScript identifiers can collide with Python reserved words. The most common case is `not` from `Data.HeytingAlgebra`:

```purescript
not :: forall a. HeytingAlgebra a => a -> a
```

Generating `not = ...` in Python causes a syntax error.

**Solution**: Append underscore to reserved words:

```haskell
identToPyName :: Ident -> Text
identToPyName ident =
  let name = toPythonIdent (runIdent' ident)
  in if nameIsPythonReserved name
     then name <> "_"
     else name
```

This transforms `not` → `not_`, `class` → `class_`, etc.

**Comparison**:
- **JavaScript**: Has fewer reserved word conflicts with PureScript
- **Erlang**: Uses atoms which have different quoting rules
- **Lua**: Similar escaping needed for Lua keywords

### 3. FFI Parameter Naming Shadows

**Problem**: When writing FFI implementations, function parameter names can shadow variables from outer scopes. We encountered this in `ordBooleanImpl`:

```python
# BUGGY VERSION
def ordBooleanImpl(lt):
    def eq(gt):           # 'eq' is the function name
        def cmp(x):
            def cmp2(y):
                if x < y: return lt
                elif x == y: return eq  # BUG: returns the function, not EQ value!
                else: return gt
```

**Solution**: Use distinct names for nested functions:

```python
# FIXED VERSION
def ordBooleanImpl(lt):
    def step_eq(eq):      # Function named 'step_eq', parameter is 'eq'
        def step_gt(gt):
            def cmp(x):
                def cmp2(y):
                    if x < y: return lt
                    elif x == y: return eq  # Now correctly refers to parameter
                    else: return gt
```

### 4. Pattern Matching as Expressions

**Problem**: PureScript `case` expressions return values, but Python's `match` statement (3.10+) is a statement, not an expression. We can't write:

```python
# This doesn't work - match is a statement
result = match x:
    case "A": 1
    case "B": 2
```

**Solution**: Use nested conditional expressions instead:

```python
# Generated code for case matching
(lambda __v__:
    (body1 if __v__[0] == "CtorA" else
        (body2 if __v__[0] == "CtorB" else
            None))
)(scrutinee)
```

For patterns with variable bindings, we use walrus operator:

```python
(lambda __v__:
    (((lambda: ((x := __v__[1]), body_using_x)[-1])())
        if __v__[0] == "Just" else
            default_body)
)(scrutinee)
```

**Pattern types handled**:
- `VarBinder`: Always matches, binds value
- `NullBinder`: Wildcard `_`, always matches
- `LiteralBinder`: Compare with literal value
- `ConstructorBinder`: Check tag, recursively match fields
- `NamedBinder`: Bind and match inner pattern

**Comparison**:
- **JavaScript**: Uses nested ternary operators (similar approach)
- **Erlang**: Native pattern matching in function clauses and case
- **Lua**: Uses if/elseif chains

### 5. Module Import Handling

**Problem**: Generated Python modules need to import their dependencies, but:
1. `Prim` modules have no runtime representation
2. Self-imports cause errors
3. Module names need Python-safe transformation

**Solution**:

```haskell
-- Filter out Prim.* modules (no runtime representation)
let isPrimModule (P.ModuleName mn) = T.isPrefixOf "Prim" mn
    imports = filter (not . isPrimModule) $
              map snd (CoreFn.moduleImports cfModule)

-- Generate header with imports
generateHeader mn imports hasForeign = T.unlines $
  [ "from purepy_runtime import *" ] ++
  (if hasForeign then ["from " <> pyModName <> "_foreign import *"] else []) ++
  [ "import " <> pyModuleNameBase depMn
  | depMn <- imports
  , depMn /= mn  -- Don't import self
  ]
```

Module name transformation: `Data.Maybe` → `data_maybe`

### 6. import * and Underscore-Prefixed Names

**Problem**: Python's `from module import *` doesn't import names starting with underscore. Our `_runtime_lazy` function wasn't being imported.

**Solution**: Define `__all__` in the runtime module:

```python
__all__ = ['unit', '_runtime_lazy', 'effect_console_log', 'run_effect']
```

## Data Representation

### Constructors as Tuples

ADT constructors are represented as tuples with a string tag:

```python
# data Maybe a = Nothing | Just a
Nothing = ("Nothing",)
Just = lambda a: ("Just", a)

# data Ordering = LT | EQ | GT
LT = ("LT",)
EQ = ("EQ",)
GT = ("GT",)
```

Pattern matching checks the tag at index 0:

```python
if value[0] == "Just":
    inner = value[1]
```

### Records as Dictionaries

PureScript records map directly to Python dicts:

```python
# { name: "Alice", age: 30 }
{"name": "Alice", "age": 30}

# Record access
record["name"]

# Record update
{**record, "age": 31}
```

### Typeclass Dictionaries

Typeclass instances are dictionaries of methods:

```python
eqInt = {"eq": lambda x: lambda y: x == y}
ordInt = {"compare": ordIntImpl(LT)(EQ)(GT), "Eq0": lambda _: eqInt}
```

## Comparison with Other Backends

| Feature | Python (purepy) | JavaScript | Erlang (purerl) | Lua |
|---------|-----------------|------------|-----------------|-----|
| Mutual recursion | `_runtime_lazy` thunks | `$runtime_lazy` (hoisting helps) | Native support | Lazy init |
| Pattern matching | Conditional expressions | Ternary operators | Native | if/elseif |
| ADT representation | Tuples with tag | Objects with tag | Atoms/tuples | Tables |
| Records | Dict | Object | Map | Table |
| Module system | Python modules | ES modules/CommonJS | Erlang modules | Lua modules |
| FFI | `_foreign.py` files | `.js` files | `.erl` files | `.lua` files |
| Reserved words | Append `_` | Minimal conflicts | Atom quoting | Append `_` |

## Performance Considerations

1. **Thunk overhead**: Every Rec binding goes through lazy thunk machinery
2. **Pattern matching**: Nested conditionals evaluate all conditions until match
3. **Currying**: Every multi-arg function creates intermediate lambdas

Potential optimizations (not yet implemented):
- Detect non-recursive Rec groups and generate simple bindings
- Use Python 3.10 `match` statement for top-level case expressions
- Uncurry functions where arity is known

## FFI Design

Foreign modules are named `<module>_foreign.py` and placed alongside generated code:

```
output-py/
  effect.py           # Generated from Effect module
  effect_foreign.py   # FFI implementations
```

Core FFI files are generated automatically for standard library modules:
- `data_eq_foreign.py` - Equality primitives
- `data_ord_foreign.py` - Comparison primitives
- `effect_foreign.py` - Effect monad primitives
- `data_semiring_foreign.py` - Arithmetic
- etc.

## Future Work

1. **Optimizations**: Uncurrying, dead code elimination, inlining
2. **Better pattern matching**: Use Python 3.10+ `match` where possible
3. **Async/await**: Map PureScript Aff to Python async
4. **Type hints**: Generate Python type annotations from PureScript types
5. **Source maps**: Map Python errors back to PureScript source

## References

- [purerl](https://github.com/purerl/purerl) - Erlang backend (architecture inspiration)
- [purescript-lua](https://github.com/pslua/purescript-lua) - Lua backend (lazy init reference)
- [PureScript CoreFn](https://github.com/purescript/purescript/tree/master/src/Language/PureScript/CoreFn) - IR documentation
