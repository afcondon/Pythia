# Python FFI Status for PureScript Backend

*Last updated: January 2026*

This document tracks the status of Python FFI implementations for the PureScript-to-Python backend (purepy).

## Overview

The purepy backend compiles PureScript to Python. Modules with JavaScript FFI require corresponding Python FFI implementations (`*_foreign.py` files) to function correctly.

## Architecture Decisions

### MonadAsyncio vs Aff

**Decision:** Use native Python `asyncio` instead of porting PureScript's `Aff`.

**Rationale:**
- Aff is deeply tied to JavaScript's event loop semantics
- Python has `asyncio` as its native async runtime
- Direct mapping to Python idioms is more maintainable
- Better interop with Python async libraries (aiohttp, asyncpg, etc.)

The `Control.Monad.Asyncio` module provides:
- Proper typeclass instances (Functor, Applicative, Monad)
- Core operations: sleep, fork, await, cancel
- Parallelism: parallel, race
- Error handling: attempt, throwError, catchError, bracket
- Effect lifting: liftEffect

## What's Different from the JavaScript Backend

This section documents intentional differences between the Python and JavaScript backends. These differences reflect platform idioms and capabilities.

### Async/Effect System

| Feature | JavaScript Backend | Python Backend |
|---------|-------------------|----------------|
| Async monad | `Aff` (purescript-aff) | `Asyncio` (Control.Monad.Asyncio) |
| Event loop | Node.js/Browser event loop | Python asyncio |
| Cancellation | Aff's cancellation semantics | asyncio.Task.cancel() |

**Migration:** Replace `Aff` imports with `Asyncio`. The API is similar but uses Python-native primitives.

### Integer Semantics

| Feature | JavaScript Backend | Python Backend |
|---------|-------------------|----------------|
| `Data.Int` | 32-bit signed integers | 32-bit signed (bitwise ops masked) |
| `Data.BigInt` | JavaScript BigInt | Python native int (arbitrary precision) |
| Overflow behavior | Silent wraparound | Arbitrary precision (no overflow) |

**Recommendation:**
- Use `Data.Int` for code that needs JS-compatible 32-bit semantics
- Use `Data.BigInt` for arbitrary precision math (zero overhead on Python since native ints are already arbitrary precision)

### Platform-Specific Modules

| JavaScript | Python Equivalent | Notes |
|------------|-------------------|-------|
| `purescript-aff` | `Control.Monad.Asyncio` | Native asyncio integration |
| `purescript-node-*` | Not yet implemented | Would wrap Python stdlib |
| `purescript-web-*` | N/A | Browser-specific, no equivalent |

### FFI Patterns

**Effects as thunks:** Both backends represent effects as zero-argument functions, but the syntax differs:

```javascript
// JavaScript
export const readFile = path => () => fs.readFileSync(path, 'utf8');
```

```python
# Python
def readFile(path):
    def effect():
        with open(path) as f:
            return f.read()
    return effect
```

**Currying:** Both backends require curried functions, but Python lacks native currying:

```python
# Multi-argument functions must be manually curried
def add(x):
    return lambda y: x + y
```

### Cross-Backend Testing Infrastructure

*Added 2026-02-24*

We now have cross-backend testing that compares Python output against the JS reference backend:

- **Test modules**: `test-project/src/Test/CrossBackend/{Strings,Numbers,ADTs,Effects,Arrays}.purs`
- **Orchestrator**: `test-project/cross_backend_test.py` — runs each module via `node` and `python3`, diffs output, produces JSONL results
- **Benchmarks**: `test-project/bench/cross_backend_bench.py` — runs benchmarks on both backends with comparison table

Known string divergences (non-BMP characters) are documented in `docs/UTF16-STRING-AUDIT.md`.

### Cross-Backend Comparison Document

A comprehensive cross-backend comparison covering purerl, purescm/purekt, purepy, and .NET has been published at `purescript-polyglot/docs/kb/research/purescript-alternative-backends-comparison.md`. This covers architecture, data representation, currying strategies, TCO, FFI patterns, string semantics, and lessons for new backends.

## Current FFI Coverage

### FFI Test Results

**90 tests passing** covering all implemented FFI modules.

**Array tests passing** - comprehensive test suite in `Test.Arrays`

**Prelude tests passing** - comprehensive test suite in `Test.Prelude`

Run the test harness:
```bash
cd test-project
python3 test_ffi.py
```

### Fully Implemented Modules

#### Effect System
| Module | FFI File | Status |
|--------|----------|--------|
| Effect | `effect_foreign.py` | ✅ |
| Effect.Console | `effect_console_foreign.py` | ✅ |
| Effect.Ref | `effect_ref_foreign.py` | ✅ |
| Effect.Uncurried | `effect_uncurried_foreign.py` | ✅ |
| Effect.Unsafe | `effect_unsafe_foreign.py` | ✅ |
| Effect.Exception | `effect_exception_foreign.py` | ✅ |

#### Control
| Module | FFI File | Status |
|--------|----------|--------|
| Control.Apply | `control_apply_foreign.py` | ✅ |
| Control.Bind | `control_bind_foreign.py` | ✅ |
| Control.Extend | `control_extend_foreign.py` | ✅ |
| Control.Monad.Rec.Class | `control_monad_rec_class_foreign.py` | ✅ |
| Control.Monad.ST.Internal | `control_monad_s_t_internal_foreign.py` | ✅ |
| Control.Monad.ST.Uncurried | `control_monad_s_t_uncurried_foreign.py` | ✅ |
| Control.Monad.Asyncio | `control_monad_asyncio_foreign.py` | ✅ |

#### Data Types - Core
| Module | FFI File | Status |
|--------|----------|--------|
| Data.Array | `data_array_foreign.py` | ✅ |
| Data.Array.ST | `data_array_s_t_foreign.py` | ✅ |
| Data.Array.ST.Partial | `data_array_s_t_partial_foreign.py` | ✅ |
| Data.Array.NonEmpty.Internal | `data_array_non_empty_internal_foreign.py` | ✅ |
| Data.Bounded | `data_bounded_foreign.py` | ✅ |
| Data.Enum | `data_enum_foreign.py` | ✅ |
| Data.Eq | `data_eq_foreign.py` | ✅ |
| Data.EuclideanRing | `data_euclidean_ring_foreign.py` | ✅ |
| Data.Foldable | `data_foldable_foreign.py` | ✅ |
| Data.FoldableWithIndex | `data_foldable_with_index_foreign.py` | ✅ |
| Data.Function.Uncurried | `data_function_uncurried_foreign.py` | ✅ |
| Data.Functor | `data_functor_foreign.py` | ✅ |
| Data.FunctorWithIndex | `data_functor_with_index_foreign.py` | ✅ |
| Data.HeytingAlgebra | `data_heyting_algebra_foreign.py` | ✅ |
| Data.Int | `data_int_foreign.py` | ✅ |
| Data.Int.Bits | `data_int_bits_foreign.py` | ✅ |
| Data.BigInt | `data_big_int_foreign.py` | ✅ |
| Data.Lazy | `data_lazy_foreign.py` | ✅ |
| Data.Number | `data_number_foreign.py` | ✅ |
| Data.Ord | `data_ord_foreign.py` | ✅ |
| Data.Reflectable | `data_reflectable_foreign.py` | ✅ |
| Data.Ring | `data_ring_foreign.py` | ✅ |
| Data.Semigroup | `data_semigroup_foreign.py` | ✅ |
| Data.Semiring | `data_semiring_foreign.py` | ✅ |
| Data.Show | `data_show_foreign.py` | ✅ |
| Data.Show.Generic | `data_show_generic_foreign.py` | ✅ |
| Data.Symbol | `data_symbol_foreign.py` | ✅ |
| Data.Traversable | `data_traversable_foreign.py` | ✅ |
| Data.TraversableWithIndex | `data_traversable_with_index_foreign.py` | ✅ |
| Data.Unfoldable | `data_unfoldable_foreign.py` | ✅ |
| Data.Unfoldable1 | `data_unfoldable1_foreign.py` | ✅ |
| Data.Unit | `data_unit_foreign.py` | ✅ |

#### Data Types - Strings
| Module | FFI File | Status |
|--------|----------|--------|
| Data.String.Common | `data_string_common_foreign.py` | ✅ |
| Data.String.CodeUnits | `data_string_code_units_foreign.py` | ✅ |
| Data.String.CodePoints | `data_string_code_points_foreign.py` | ✅ |
| Data.String.Unsafe | `data_string_unsafe_foreign.py` | ✅ |

#### Foreign Data
| Module | FFI File | Status |
|--------|----------|--------|
| Foreign.Index | `foreign_index_foreign.py` | ✅ |
| Foreign.Keys | `foreign_keys_foreign.py` | ✅ |

#### Partial/Unsafe
| Module | FFI File | Status |
|--------|----------|--------|
| Partial | `partial_foreign.py` | ✅ |
| Partial.Unsafe | `partial_unsafe_foreign.py` | ✅ |
| Unsafe.Coerce | `unsafe_coerce_foreign.py` | ✅ |
| Record.Unsafe | `record_unsafe_foreign.py` | ✅ |

#### Testing
| Module | FFI File | Status |
|--------|----------|--------|
| Test.Assert | `test_assert_foreign.py` | ✅ |

### Not Applicable (JS-Specific)

These packages are JavaScript-specific and will not be ported:

- `aff` - Using MonadAsyncio instead
- `web-dom`, `web-html`, `web-events` - Browser APIs
- `node-buffer`, `node-fs`, `node-path`, `node-process` - Node.js APIs

## FFI Implementation Notes

### Uncurried Function Signatures

Many FFI functions use uncurried signatures for efficiency (matching the JS FFI):

```python
# Uncurried (matches JS FFI)
def indexImpl(just, nothing, xs, i):
    if i < 0 or i >= len(xs):
        return nothing
    return just(xs[i])

# vs Curried
def indexImpl(just):
    def step(nothing):
        def step2(xs):
            def step3(i):
                ...
```

### 32-bit Integer Semantics

Python integers have arbitrary precision. For JS compatibility, bitwise operations must mask to 32 bits:

```python
def _to_int32(n):
    n = n & 0xFFFFFFFF
    if n >= 0x80000000:
        n -= 0x100000000
    return n
```

### Export Visibility

Python's `import *` ignores names starting with underscore. Use `__all__` to export underscore-prefixed names:

```python
__all__ = ['_crashWith', '_unsafePartial', ...]
```

## FFI Implementation Guidelines

### Effect Pattern

Effects are thunks (zero-argument functions):

```python
def pureE(a):
    return lambda: a

def bindE(a):
    return lambda f: lambda: f(a())()
```

### Currying Pattern

Multi-argument functions must be curried:

```python
# f(x, y, z) becomes f(x)(y)(z)
def add(x):
    return lambda y: x + y
```

### File Naming Convention

PureScript module `Foo.Bar.Baz` maps to:
- Generated code: `foo_bar_baz.py`
- FFI file: `foo_bar_baz_foreign.py`

Note: CamelCase converts to snake_case:
- `Data.HeytingAlgebra` → `data_heyting_algebra_foreign.py`
- `Control.Monad.ST.Internal` → `control_monad_s_t_internal_foreign.py`

## Build Process

```bash
# Full pipeline
spago build                    # Generate CoreFn
purepy output output-py        # CoreFn → Python
cp src/*_foreign.py output-py/ # Copy FFI files

# Run
python3 -c "import main; main.main()"
```

## Progress Tracking

### Completed
1. [x] Implement missing FFI for 5 core module gaps
2. [x] Create `control_monad_asyncio_foreign.py`
3. [x] Implement FFI for `purescript-assert`
4. [x] Set up automated test harness (90 tests)
5. [x] Implement Priority 2 packages (strings, integers, numbers, foreign, lazy, exceptions)
6. [x] Fix uncurried FFI signatures to match JS FFI
7. [x] Implement FFI for lists and ordered-collections
   - `purescript-lists` - Pure PureScript, no FFI needed
   - `purescript-ordered-collections` - Pure PureScript, no FFI needed
   - Extended `mkFn/runFn` to support 6-10 arguments for Map internals

8. [x] Fix guarded pattern matching code generation bug
   - Constructor tag checks were missing for guarded patterns
   - Fixed in `Make.hs:generateAlt` for `Left guards` case

9. [x] Run purescript-arrays tests on Python backend
   - Created comprehensive `Test.Arrays` module
   - All tests pass including: construction, indexing, cons/snoc, uncons/unsnoc, transformations, folds, find operations, modification, sorting, take/drop, span/group, zip

10. [x] Run purescript-prelude tests on Python backend
    - Created `Test.Prelude` module covering Eq, Ord, Show, Semiring, Ring, EuclideanRing, Boolean ops, function composition, Functor, Apply, Applicative, Bind, Maybe, Either, Tuple, Semigroup, Monoid
    - Fixed `showStringImpl` to use double quotes (matching JS semantics)
    - Fixed `showArrayImpl` to not add spaces after commas
    - All tests pass

11. [x] Implement record pattern matching in purepy
    - Added `ObjectLiteral` and `ArrayLiteral` pattern matching to `Make.hs`
    - Enables destructuring records like `{ head: h, tail: t }` in case expressions

### Future Work
12. [ ] Priority 3 packages - Python ecosystem integration
    - Database bindings (SQLAlchemy, asyncpg)
    - HTTP client (aiohttp, httpx)
    - File system async operations
    - Additional data science integrations (numpy, pandas)

### Known Issues

**FFI File Regeneration:** Running `purepy` overwrites FFI files in `output-py-new`. Keep authoritative copies in `ffi-py/` directory and copy after regeneration.
