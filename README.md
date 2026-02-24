# purescript-python

A PureScript backend that compiles to Python.

## Status

**Working** - Hello World and core libraries compile and run successfully.

### What Works

- [x] Basic data types (Int, Number, String, Boolean)
- [x] Records (as Python dicts)
- [x] Arrays (as Python lists)
- [x] Functions and currying
- [x] ADTs/constructors (as tuples with tag)
- [x] Pattern matching (via conditional expressions)
- [x] Mutually recursive bindings (lazy thunk pattern)
- [x] Module imports and dependencies
- [x] FFI to Python (`_foreign.py` files)
- [x] Standard library bindings (Effect, Eq, Ord, Show, etc.)

### Example

```purescript
-- src/Main.purs
module Main where

import Prelude
import Effect (Effect)
import Effect.Console (log)

main :: Effect Unit
main = log "Hello from PureScript!"
```

```bash
$ spago build
$ purepy output output-py
$ python3 -c "import sys; sys.path.insert(0, 'output-py'); import main; main.main()"
Hello from PureScript!
```

## Installation

### Prerequisites

- [Stack](https://docs.haskellstack.org/) (Haskell build tool)
- [PureScript](https://www.purescript.org/) 0.15.14
- [Spago](https://github.com/purescript/spago) (PureScript package manager)
- Python 3.10+ (for match statement support)

### Building from Source

```bash
git clone https://github.com/your-username/purescript-python.git
cd purescript-python
stack build
```

## Usage

1. Create a PureScript project with Spago
2. Build with `spago build`
3. Run `purepy` to generate Python files in `output-py/`
4. Import and run your Python modules

## Architecture

The compiler works in stages:

1. **PureScript Compiler** generates CoreFn (JSON intermediate representation)
2. **purepy** reads CoreFn and transforms it to a Python AST
3. **Pretty Printer** converts the AST to Python source code

### Key Mappings

| PureScript | Python |
|------------|--------|
| `Int` | `int` |
| `Number` | `float` |
| `String` | `str` |
| `Boolean` | `bool` |
| `Array a` | `list` |
| `Record { x :: Int }` | `dict` |
| `data Maybe a = Nothing \| Just a` | `tuple` (e.g., `("Just", value)`) |
| `f x y = x + y` | `f = lambda x: lambda y: x + y` |

## FFI

Foreign imports are supported via Python modules. For a module `Foo.Bar`:

```purescript
-- src/Foo/Bar.purs
module Foo.Bar where

foreign import myFunction :: Int -> Int
```

Create the corresponding Python file:

```python
# src/Foo/Bar_foreign.py
def myFunction(x):
    return x * 2
```

## Testing

### FFI Tests

```bash
cd test-project
python3 test_ffi.py         # 90+ FFI unit tests
```

### Cross-Backend Tests

Compare Python backend output against the JS reference backend:

```bash
cd test-project
python3 cross_backend_test.py    # Run same PureScript on node + python3, diff output
```

This produces JSONL to stdout and a summary table to stderr. Known string divergences (non-BMP/emoji characters) are flagged as expected. See `docs/UTF16-STRING-AUDIT.md` for details.

### Benchmarks

```bash
cd test-project
python3 bench/run_benchmarks.py          # PureScript-Python vs hand-written Python
python3 bench/cross_backend_bench.py     # JS vs Python vs hand-written, with JSONL tracking
```

## Development

### Project Structure

```
purescript-python/
├── app/Main.hs                           # CLI entry point
├── src/Language/PureScript/Python/
│   ├── Make.hs                           # Main compiler: CoreFn → Python
│   └── CodeGen/
│       └── Common.hs                     # Identifier handling, module names
├── docs/
│   └── IMPLEMENTATION-NOTES.md           # Implementation details
├── test-project/                         # Example PureScript project
│   ├── src/Main.purs
│   ├── output/                           # PureScript CoreFn output
│   └── output-py/                        # Generated Python
└── package.yaml                          # Build configuration
```

### Running Tests

```bash
stack test
```

## Documentation

- [Implementation Notes](docs/IMPLEMENTATION-NOTES.md) - Detailed notes on challenges and solutions, including comparison with other backends (JavaScript, Erlang, Lua)
- [Roadmap](docs/ROADMAP.md) - Performance optimizations, FFI improvements, and future direction

## Credits

This project is based on the architecture of:

- [purerl](https://github.com/purerl/purerl) - Erlang backend for PureScript
- [purescript-backend-optimizer](https://github.com/aristanetworks/purescript-backend-optimizer) - Optimization pipeline

## License

BSD-3-Clause
