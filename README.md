# purescript-python

A PureScript backend that compiles to Python.

## Status

**Early Development** - This is an initial implementation based on the architecture
of [purerl](https://github.com/purerl/purerl) (the Erlang backend).

### What Works (Planned)

- [x] Basic data types (Int, Number, String, Boolean)
- [x] Records (as Python dicts)
- [x] Arrays (as Python lists)
- [x] Functions and currying
- [x] ADTs/constructors (as tuples)
- [ ] Pattern matching (via if/elif or match statements)
- [ ] FFI to Python
- [ ] Standard library bindings

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

## Development

### Project Structure

```
purescript-python/
├── app/                    # CLI entry point
├── src/Language/PureScript/Python/
│   ├── CodeGen.hs         # CoreFn → Python AST
│   ├── CodeGen/
│   │   ├── AST.hs         # Python AST types
│   │   └── Common.hs      # Utility functions
│   └── Pretty.hs          # AST → Python source
├── tests/                  # Test suite
└── package.yaml           # Build configuration
```

### Running Tests

```bash
stack test
```

## Credits

This project is based on the architecture of:

- [purerl](https://github.com/purerl/purerl) - Erlang backend for PureScript
- [purescript-backend-optimizer](https://github.com/aristanetworks/purescript-backend-optimizer) - Optimization pipeline

## License

BSD-3-Clause
