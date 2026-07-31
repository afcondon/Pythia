# Pythia — purescript-python (`purepy`)

A PureScript backend that compiles to Python. **Pythia** — the oracle —
is the Python member of the polyglot-PureScript backends family,
alongside [Jurist](../purescript-julia/) (PureScript → Julia, *the
judge*) and [Gnomon](../purescript-go/) (PureScript → Go, *the
indicator*). The three share the same architecture, the same ADR
discipline, the same differential-conformance method, and (deliberately)
the same test corpus.

Rebooted 2026-06-11 on the Jurist skeleton — see
[`docs/design-decisions/`](docs/design-decisions/) for why and how, and
[`docs/python-shaped-libraries.md`](docs/python-shaped-libraries.md) for
what the backend is *for* (the design direction: typed faces on Python's
staging engines — numpy, sympy/scipy, DuckDB — and the Python column of
the family's verb matrix).

## Status

**Conformant on the shared corpus**: 556/561 tests byte-identical with
the reference JS backend, 5 documented divergences, 0 failures
(`test-suite/run_tests.py`, corpus shared with Jurist and Gnomon — all
three report the identical figure, which is the method working). The
divergence ledger:

- `INT64-*` — JS wraps every Int operation to int32 (`|0`); Python ints
  are arbitrary precision. The JS values are the overflowed ones.
- `ASTRAL-*` — JS counts UTF-16 code units; Python strings are
  codepoint sequences. Identical for BMP text. (Full background:
  `docs/UTF16-STRING-AUDIT.md`.)

### And against the compiler's own test suite

That corpus is one **we wrote**, so it can only prove parity on cases someone
thought of. `purescript/purescript`'s `tests/purs/passing` is the suite the
compiler team wrote to *define the language*:

```
341/347 = 98.3%   tests/purs/passing @ v0.15.15   purepy      (the oracle)
343/347 = 98.8%   tests/purs/passing @ v0.15.15   backend-py  (ADR-0003)
```

Most of the remaining causes are common to more than one backend — the failures
are in the shared model, not in this lowering. Full analysis:
`docs/kb/reference/purs-corpus-b4-results.md` in the `docs` repo.

The headline from first contact was **`CODEGEN_ERR` = 0**: across 364 tests
probing rank-N types, functional dependencies, instance chains, `Coercible`
and typelevel symbols, nothing made the code generator refuse or crash.

## Two implementations, on purpose

There are **two backends in this repo** — see
[ADR-0003](docs/design-decisions/0003-two-implementations.md). `purepy`
(`src/`, Haskell, raw CoreFn) is the correctness **oracle**; `backend-py/`
(PureScript) consumes `purescript-backend-optimizer`'s IR and gets its TCO,
inlining and dead-code elimination rather than re-deriving them. Correctness
claims rest on the oracle, and the method is that both lanes run the same
corpus against the same JavaScript reference.

They **share one runtime and one set of foreign shims**: `backend-py` emits
module bodies only, and copies in `purepy`'s `_purepy_runtime.py` and
`<Module>_foreign.py` unmodified. Gnomon kept two Go runtimes and they silently
diverged by two symbols; here a fork is structurally unavailable.

## How it works

`purepy` is a from-scratch CoreFn → Python code generator (Haskell). It
consumes the CoreFn JSON that `purs` emits and writes one Python module
per PureScript module, plus a small runtime (`_purepy_runtime.py`) and
built-in FFI shims for the core libraries. There is no loader: Python's
own imports resolve dependency order.

Representation (see ADR-0002): ADTs are tag-tuples (`("Just", x)`),
records are dicts, functions are curried unary closures, effects are
zero-argument thunks, and every lambda is hoisted to a module-level
`def` with its free variables passed explicitly — CPython caps paren
nesting, so continuation depth must become flat sibling defs. Bindings
whose self-references are all saturated tail calls compile to dispatch
loops (stack-safe without `MonadRec`).

## Usage

```bash
# Build the compiler
stack build

# In a spago project: emit CoreFn alongside JS
spago build --purs-args "--codegen corefn"   # or drive purs directly

# Generate Python
stack exec purepy -- output output-py

# Run (main.py is generated when a Main module exists)
python3 output-py/main.py
```

User FFI: put `<Module_Name>_foreign.py` files in `ffi-py/` at the
project root — they are copied into the output last, so they win over
the built-in shims. Define the mangled foreign names (the generated
module imports them by name, which doubles as an import-time signature
canary).

## Conformance

```bash
cd test-suite
python3 run_tests.py          # spago build + purs corefn,js + purepy + diff
python3 run_tests.py --skip-build
```

The `Test.*` corpus is shared with Jurist
(`../purescript-julia/test-suite/src`) — one family conformance kit,
per-backend divergence ledgers.

## Repository layout

- `src/`, `app/` — the compiler (Haskell; purejl-skeleton architecture)
- `backend-py/` — the optimizer-consumer lane (PureScript; ADR-0003)
- `test-suite/` — the differential conformance suite
- `docs/design-decisions/` — ADRs (family format)
- `docs/` — design direction + carried-over analyses (UTF-16 audit,
  tailrec notes, Aff/asyncio design)
- `test-project/`, `bundle/`, `ci/` — first-incarnation artifacts,
  pending cleanup. (The first incarnation's two compiler implementations
  were retired to git history per ADR-0001 — see the `attic/` removal
  commit.)
