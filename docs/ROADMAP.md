# PureScript Python Backend: Roadmap

This document outlines the performance considerations, FFI improvements, and future direction for the PureScript-Python backend.

## Vision: The Language Stack

The sweet spot for PureScript-Python is as a **type-safe orchestration layer** over Python's rich ecosystem:

```
┌─────────────────────────────────────────────────────────────────┐
│  PureScript                                                     │
│  • Business logic with full type safety                         │
│  • Composable abstractions (monads, applicatives, etc.)         │
│  • Correct error handling (Maybe, Either, Aff)                  │
│  • Property-based testing, refinement types                     │
├─────────────────────────────────────────────────────────────────┤
│  Thin FFI Layer                                                 │
│  • Auto-generated wrappers for Python libraries                 │
│  • Uncurried functions for natural Python interop               │
│  • Type-safe bindings with minimal overhead                     │
├─────────────────────────────────────────────────────────────────┤
│  Python Ecosystem                                               │
│  • NumPy, Pandas, Polars (data manipulation)                    │
│  • PyTorch, TensorFlow, JAX (machine learning)                  │
│  • Matplotlib, Plotly (visualization)                           │
│  • FastAPI, Django (web frameworks)                             │
│  • SQLAlchemy, asyncpg (databases)                              │
│  └── Already optimized C/Fortran/CUDA under the hood            │
└─────────────────────────────────────────────────────────────────┘
```

### Mixed Codebases

In practice, teams may have both PureScript and Python developers working together:

```
project/
├── src/                    # PureScript source
│   ├── Core/               # Business logic, types, validation
│   ├── Pipeline/           # Data pipeline orchestration
│   └── API/                # Type-safe API definitions
├── python/                 # Native Python code
│   ├── models/             # ML model implementations
│   ├── notebooks/          # Jupyter exploration
│   └── scripts/            # Ad-hoc tooling
├── output-py/              # Generated Python (gitignored)
└── app/                    # Combined application
    └── main.py             # Entry point, imports both
```

Python developers can:
- Work in familiar Python for exploratory/ML code
- Import and use PureScript-generated modules
- Benefit from PureScript's type safety at boundaries

PureScript developers can:
- Write core logic with full type safety
- Call into Python libraries via FFI
- Trust that the generated code integrates seamlessly

---

## Current Limitations

### Performance Overhead

| Issue | Description | Impact |
|-------|-------------|--------|
| **Currying** | Every multi-arg function creates nested lambdas | Memory allocation, call overhead |
| **Thunks** | Lazy initialization for recursive bindings | Indirection on every access |
| **Pattern matching** | Nested conditional expressions | Sequential evaluation |
| **Dictionary passing** | Typeclass instances as explicit arguments | Extra function arguments |
| **No TCO** | Python lacks tail-call optimization | Stack overflow on deep recursion |

### FFI Ergonomics

| Issue | Description |
|-------|-------------|
| **Manual currying** | Python functions must be manually curried to match PureScript signatures |
| **Effect wrapping** | Effect-returning functions need explicit thunk wrappers |
| **No type checking** | No verification that Python implementations match PureScript types |
| **Boilerplate** | Large libraries require extensive manual wrapper code |

---

## Optimization Roadmap

### Phase 1: Compiler Improvements (Immediate)

#### 1.1 Uncurrying

Detect saturated function applications and generate direct calls:

```python
# BEFORE: Curried (current)
f = lambda x: lambda y: lambda z: x + y + z
result = f(1)(2)(3)  # 3 function calls, 2 intermediate lambdas

# AFTER: Uncurried (optimized)
def f(x, y, z):
    return x + y + z
result = f(1, 2, 3)  # 1 function call, no intermediates
```

**Implementation approach:**
- Track function arity from Abs chains in CoreFn
- Detect fully-saturated App chains
- Generate uncurried definitions and calls
- Fall back to curried for partial application

**Expected impact:** 2-3x speedup for function-heavy code

#### 1.2 Smart Rec Detection

Only use lazy thunks for actually-recursive binding groups:

```python
# BEFORE: All Rec groups use thunks
_lazy_x = _runtime_lazy("x", "Module", lambda: some_expr)
_lazy_y = _runtime_lazy("y", "Module", lambda: other_expr)
x = _lazy_x()
y = _lazy_y()

# AFTER: Non-recursive Rec groups use direct assignment
x = some_expr
y = other_expr

# Only actually recursive groups use thunks
_lazy_a = _runtime_lazy("a", "Module", lambda: ... _lazy_b() ...)
_lazy_b = _runtime_lazy("b", "Module", lambda: ... _lazy_a() ...)
a = _lazy_a()
b = _lazy_b()
```

**Implementation approach:**
- Build dependency graph within Rec group
- Detect strongly-connected components
- Only wrap truly recursive components in thunks

**Expected impact:** Reduced overhead for most bindings

#### 1.3 Inlining

Inline small, frequently-used functions:

```python
# BEFORE
identity = lambda x: x
const = lambda a: lambda b: a
result = identity(const(1)(2))

# AFTER (inlined)
result = 1
```

**Candidates for inlining:**
- `identity`, `const`, `flip`
- Dictionary accessors (`dict["field"]`)
- Newtype constructors/destructors
- Single-use local bindings

#### 1.4 Dead Code Elimination

Remove unused bindings from generated output:

- Track which exports are actually used
- Remove unused local bindings
- Remove unused imports

### Phase 2: FFI Improvements (Short-term)

#### 2.1 Stub Generation

Generate `_foreign.py` templates from PureScript foreign declarations:

```purescript
-- src/MyModule.purs
module MyModule where

foreign import readFile :: FilePath -> Effect String
foreign import writeFile :: FilePath -> String -> Effect Unit
foreign import processData :: Array Number -> Number
```

Generated stub:
```python
# output-py/my_module_foreign.py
# AUTO-GENERATED from MyModule foreign imports
# Implement the functions below

def readFile(path):
    """FilePath -> Effect String"""
    def effect():
        # TODO: Implement
        raise NotImplementedError("readFile")
    return effect

def writeFile(path):
    """FilePath -> String -> Effect Unit"""
    def inner(content):
        def effect():
            # TODO: Implement
            raise NotImplementedError("writeFile")
        return effect
    return inner

def processData(arr):
    """Array Number -> Number"""
    # TODO: Implement
    raise NotImplementedError("processData")
```

#### 2.2 Uncurried FFI

Support `EffectFnN` and `FnN` types for natural Python interop:

```purescript
-- PureScript
foreign import readFileSync :: EffectFn1 FilePath String
foreign import addThree :: Fn3 Int Int Int Int
```

```python
# Python - no currying needed!
def readFileSync(path):
    with open(path) as f:
        return f.read()

def addThree(a, b, c):
    return a + b + c
```

The compiler generates currying wrappers only when needed:
```python
# Generated wrapper for partial application
def readFileSync_curried(path):
    return lambda: readFileSync(path)
```

#### 2.3 Library Binding Generator

For major Python libraries, generate PureScript bindings from type stubs:

```bash
purepy-bindgen numpy --output src/Python/NumPy.purs
```

Generates:
```purescript
module Python.NumPy where

foreign import data NDArray :: Type -> Type

foreign import zeros :: Array Int -> Effect (NDArray Number)
foreign import dot :: NDArray Number -> NDArray Number -> Effect (NDArray Number)
-- etc.
```

### Phase 3: Python-Specific Optimizations (Medium-term)

#### 3.1 Python 3.10+ Match Statements

For top-level case expressions, generate native match:

```python
# BEFORE: Conditional expression
def show_ordering(v):
    return (lambda __v__:
        ("LT" if __v__[0] == "LT" else
            ("GT" if __v__[0] == "GT" else
                ("EQ" if __v__[0] == "EQ" else None))))(v)

# AFTER: Match statement
def show_ordering(v):
    match v:
        case ("LT",): return "LT"
        case ("GT",): return "GT"
        case ("EQ",): return "EQ"
```

**Challenge:** `match` is a statement, not expression. Requires restructuring code generation for case expressions that aren't in expression position.

#### 3.2 Type Hints Generation

Generate Python type annotations for better tooling and mypyc compatibility:

```python
from typing import Callable, TypeVar, Generic

A = TypeVar('A')
B = TypeVar('B')

def map_(f: Callable[[A], B]) -> Callable[[list[A]], list[B]]:
    def inner(xs: list[A]) -> list[B]:
        return [f(x) for x in xs]
    return inner
```

**Benefits:**
- IDE autocompletion in Python editors
- Runtime type checking with `beartype` or `typeguard`
- Compilation to C with mypyc

#### 3.3 ADT Representation with `__slots__`

Use classes with `__slots__` instead of tuples for ADTs:

```python
# BEFORE: Tuple representation
Just = lambda a: ("Just", a)
Nothing = ("Nothing",)

# AFTER: Class with __slots__
class Just:
    __slots__ = ('value',)
    __match_args__ = ('value',)
    def __init__(self, value):
        self.value = value

class Nothing:
    __slots__ = ()
    __match_args__ = ()
    _instance = None
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
```

**Benefits:**
- Lower memory usage
- Better match statement integration
- Clearer error messages

### Phase 4: Alternative Execution (Long-term)

#### 4.1 Cython Backend

Generate `.pyx` files for C-level performance:

```cython
# Generated .pyx file
cdef class Just:
    cdef public object value
    def __init__(self, value):
        self.value = value

cpdef int add(int x, int y):
    return x + y
```

**Use case:** Performance-critical inner loops

#### 4.2 PyPy Compatibility

Ensure generated code JITs efficiently on PyPy:

- Avoid `eval`/`exec`
- Use simple, predictable patterns
- Prefer iteration over recursion
- Avoid excessive lambda creation in hot paths

**Expected impact:** 5-50x speedup with zero code changes

#### 4.3 Numba Integration

For numeric code, support Numba JIT:

```python
import numba

@numba.jit(nopython=True)
def hot_numeric_function(arr):
    result = 0.0
    for x in arr:
        result += x * x
    return result
```

**Use case:** NumPy-based numerical computing

#### 4.4 mypyc Compilation

With type hints, compile to C extensions:

```bash
# Compile generated Python to C extensions
mypyc output-py/data_*.py output-py/control_*.py

# Results in .so files that Python imports transparently
```

**Expected impact:** 2-10x speedup for type-annotated code

---

## Benchmarking Plan

### Micro-benchmarks

| Benchmark | Measures |
|-----------|----------|
| `fib(35)` | Recursive function calls |
| `sum [1..1000000]` | List operations, folds |
| `map (*2) [1..100000]` | Higher-order functions |
| `show largeADT` | Pattern matching |
| `traverse effect list` | Monadic operations |

### Comparison Targets

- PureScript → JavaScript (baseline)
- PureScript → Python (our backend)
- Hand-written Python equivalent
- Python with PyPy
- Python with mypyc

### Profiling

Use Python's built-in profiling:

```bash
python -m cProfile -s cumtime output-py/main.py
```

Key metrics:
- Total runtime
- Function call count
- Time per function
- Memory allocation

---

## Implementation Priority

### Immediate (This Session)

1. **Benchmarking suite** - Establish baseline measurements
2. **Uncurrying** - Biggest performance win
3. **FFI stub generator** - Improve developer experience
4. **Smart Rec detection** - Reduce thunk overhead

### Short-term (Next Few Sessions)

5. Type hints generation
6. Uncurried FFI (`FnN`, `EffectFnN`)
7. Inlining pass
8. Dead code elimination

### Medium-term

9. Python 3.10 match statements
10. `__slots__` ADT representation
11. Library binding generator
12. PyPy compatibility testing

### Long-term / Exploratory

13. Cython backend
14. Numba integration
15. mypyc compilation
16. purescript-backend-optimizer integration

---

## References

- [purescript-backend-optimizer](https://github.com/aristanetworks/purescript-backend-optimizer) - Common optimization infrastructure
- [mypyc](https://mypyc.readthedocs.io/) - Compile type-annotated Python to C
- [Cython](https://cython.org/) - C extensions for Python
- [Numba](https://numba.pydata.org/) - JIT compiler for numeric Python
- [PyPy](https://www.pypy.org/) - Fast Python implementation with JIT
