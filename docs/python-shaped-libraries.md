# Python-shaped libraries: giving Python's powers a PureScript face

Design notes (2026-06-11) on the Jurist-revisit question: what would make
this backend a *designed* artifact rather than an engineering one — not API
wrappers over Python libraries, but structures that make the combination
better than either side alone? Companion to the orientation brief
(`REVISIT-BRIEF.md`); method ported from Jurist's
`../../purescript-julia/docs/julia-shaped-libraries.md` and ADR-0007.
All receipts below are real runs on this machine (2026-06-11), not
paraphrases.

## Python's superpower, named precisely

Julia's superpower was the specializing JIT, and the doctrine ("descriptions
across, handles back") followed from it. Python's superpower is different and
twofold:

1. **The ecosystem is the world's default substrate.** numpy/scipy/pandas,
   sympy, scikit-learn/PyTorch, DuckDB, notebooks. Python is where the data
   and the libraries already live; it wins by gravity, not by speed.
2. **Performant Python already lives by our doctrine.** Every fast Python
   library is a staging engine: numpy broadcasting (description = the ufunc
   expression, engine = C loops), polars LazyFrames (description = an
   expression DAG the optimizer rewrites), JAX (description = a traced
   graph, engine = XLA), PyTorch (graphs → kernels), DuckDB's relational
   API (description = relational algebra, engine = vectorized C++). "Never
   write a Python-level loop over a numpy array" is the callback
   anti-pattern as folk wisdom.

So the Jurist doctrine is not an import here — it is *how good Python is
already written*. What Python lacks, and PureScript supplies, is a typed
language for the descriptions. The pitch in one line: **PureScript as the
type system Python's staging engines never had.**

### The anti-pattern, measured (receipts)

The curried-Dict glue cost and the callback penalty, this machine, CPython
3.13, 2026-06-11:

```
curried f(1)(2)(3):  257.5 ns/call      (the purepy glue shape)
plain   g(1,2,3)  :   59.4 ns/call      (4.3× — cf. Jurist's 325 ns measurement)
numpy 1e6 elements, per-element Python callback: 161 ms
numpy 1e6 elements, broadcast                  :   1.1 ms   (145×)
```

Any design where the hot loop crosses the PS↔Python seam per element is
dead on arrival — same conclusion as Jurist, same cure: the seam is crossed
**once**, carrying a typed description; what returns are **handles** to
Python-owned data (an `np.ndarray`, a DuckDB relation, a solver solution),
scoped ST-style so they cannot escape; only an explicit `freeze`/`sample`
materializes into PS-land.

## Tier 1 — typed handles over numpy (incremental; near-term)

The direct port of Jurist Tier 1: `STNumberVector h` backed by
`numpy.ndarray(dtype=float64)` (not a Python list), with a vocabulary of
fused kernels (`axpy`, `dot`, `scale`, `clamp`, `normL2`, slices, …) and
`freeze :: forall h. STNumberVector h -> ST h (Array Number)`. The general
`mapNum` with a PS closure is rejected for the measured 145× reason; the
escape hatch is the Tier-2 expression AST compiled to a broadcast.

Payoff: numpy's C loops and BLAS through a region-disciplined typed surface.
Same effort class as Jurist's (a weekend); same natural extension to
`STMatrix h` over 2-D arrays with `numpy.linalg` factorizations.

## Tier 2 — the fourth column: numexpr-core on Python

Jurist's `examples/numexpr-edsl` is already split into a backend-agnostic
**`core`** (FFI-free: `Data.NumExpr`, `Data.SystemSpec`, `Data.DAESpec`,
`integratePure`) plus denotation workspaces `julia/`, `node/`, `beam/`. The
single highest-leverage move for this backend: add **`python/`** — the same
`lorenz` description, a purepy denotation, a fourth runtime in the family
matrix. Nothing about `core` needs to change; that is the whole point of the
2026-06-10 restructuring.

The staging path that makes the column honest — **sympy is the symbolic
stack, `lambdify` is the RGF analog, scipy is the solver** — probed
end-to-end today:

```
NumExpr/SystemSpec  →  sympy.Matrix (symbolic RHS)
                    →  rhs_sym.jacobian(...)            # analytic, never hand-written
                    →  sp.lambdify(..., 'numpy')        # codegen, once, at the seam
                    →  solve_ivp(method='Radau', jac=…) # implicit stiff solver
receipt: Lorenz maxZ = 47.834   (Jurist RK4 47.834 / MTK 47.69 — in the envelope)
```

And the verbs (`Data.Verbs`, the `Answer` IOU from Jurist ADR-0007's
addenda), graded honestly:

| verb | Node/BEAM | **Python** | Julia |
|---|---|---|---|
| `eval` / `integrate` | pure PS (real, cruder) | lambdify + solve_ivp (adaptive, stiff via Radau + analytic Jacobian) | MTK polyalgorithm |
| `differentiate` (LaTeX) | `Deferred` | **`Computed`** — `sympy.diff` + `sp.latex`; receipt: ∇[10x² − xy + sin y + log x] = [20x − y + 1/x, −x + cos y], typeset | Symbolics + Latexify |
| `provenRoots` | `Deferred` | guesses (`scipy`), uncertified; `sympy.solveset` *can* prove the polynomial cases | proven enclosures, exhaustive (IntervalRootFinding) |
| `solveDAE` | `Deferred` | `Deferred` — scipy has no algebraic-variable support (the receipt Jurist's double pendulum already cites) | Rodas5P |

This makes the Python column the **middle tier the matrix didn't have**: it
computes far more than Node/BEAM, and the residue — what stays `Deferred` or
uncertified — is precisely the demonstration of what Julia is *for*. The
guess-vs-proof taxonomy stops being a claim and becomes a visible gradient
across four columns. A better Python backend is a better Polyglot exhibit
exactly here.

(Toolbox present on this machine today: numpy 2.3.5, scipy 1.16.3,
sympy 1.14.0, numba 0.63.1, pandas 2.3.3, duckdb 1.4.4. Absent but
installable: polars, jax, marimo — marimo is among the reference clones in
`~/work/afc-work/GitHub/`.)

## Tier 2′ — the flagship: typed dataframe/query descriptions

Julia got the `SystemSpec` eDSL because Julia's heart is SciML. **Python's
heart is dataframes**, so the genuinely Python-shaped flagship is the typed
query surface — the "Om-shaped" idea from Jurist's `julia-hosted-purescript`
doc, landed where it belongs:

```purescript
type Listens = ( artist :: String, track :: String, played_at :: Timestamp )

topArtists :: Query Listens ( artist :: String, n :: Int )
topArtists = from listens
  # groupBy @"artist"
  # aggregate { n: count }
  # orderBy (desc @"n")
  # limit 20
```

— where a misspelt column or an aggregation of the wrong type is **a compile
error in the browser**, and the denotation is an engine that already wants a
description:

- **DuckDB first** (installed, and the home-world engine: CodeExplorer,
  the larder, Marginalia analytics). The relational API / generated SQL is
  the description; results come back as handles (relations / Arrow), sampled
  explicitly. This also rhymes directly with the standing
  query-schema-visualization ambitions (Humboldt; yoga-postgres-om prior
  art on the type-level side).
- **polars lazy** second: `LazyFrame` is an optimizing expression DAG —
  the most doctrine-shaped object in Python — but polars isn't installed
  and DuckDB covers the same ground for the first demo.
- pandas only as a materialization target (`freeze`), never the engine.

The old ROADMAP's K1 ("type-safe Pandas") was this idea in wrapper clothing.
The Jurist lesson is to ship it as a *description language with a remote
engine*, not as bindings: no per-row callbacks, no `map` with PS closures —
expressions only, the same fork as `mapNum`.

## Tier 3 — Python-hosted PureScript (the slider's View 2)

The mirror direction, per Jurist's `julia-hosted-purescript.md`: a Python
process (REPL, Jupyter, marimo notebook) is the host; compiled PS loads as a
typed library whose well-formedness was settled at compile time. purepy
output is ordinary Python modules, so the probe is the same shape as
Jurist's (`import` instead of `include`); the calling convention from the
host side (curried unary closures, Effects as zero-arg thunks, tag-tuple
ADTs) is already documented in `IMPLEMENTATION-NOTES.md`.

Compelling uses, same ranking logic as Jurist's:

1. **Typed wire contract** — one PS module of request/response ADTs +
   codecs, compiled with the JS backend for the browser AND purepy for the
   Python service (FastAPI). Schema drift structurally impossible;
   differential round-trip receipts prove it.
2. **Verified components as plain Python source** — invariant-heavy logic
   (parsers, state machines, eligibility rules) written in PS, shipped as a
   directory of `.py` files; `import` and call, no FFI ceremony.
3. **The reference oracle in-session** — `integratePure`/`eval` loaded next
   to the fast numpy implementation; property-test against it from the REPL.
4. **marimo / ShapedSteer cells** — marimo's reactive dataflow is
   ShapedSteer-adjacent; purepy cells are the standing ambition
   (cells-as-Python-computations). Don't foreclose it; don't lead with it.

Same caveat as Julia-hosted: the type discipline does **not** follow you
into the REPL — guarantees are properties of the compiled artifact, so the
compelling uses are pre-typechecked PS hosted by Python, not free-form
PS-from-Python.

## What makes these attractive rather than bindings

- The PS types add what mypy structurally cannot: row-typed schemas and
  state spaces, exhaustive ADT matching, effect tracking, region-scoped
  handle lifetimes.
- The Python side runs at full library speed because nothing hot crosses
  the seam — the 145× receipt is the design rule, not a hope.
- The same typed descriptions (`numexpr-core`, the query eDSL) deploy
  across the whole family: browser renders, BEAM coordinates, Python
  computes-and-glues, Julia proves. The Python column completes the
  guess-vs-proof gradient.
- Every piece feeds the Polyglot curator story: one description, four
  runtimes, receipts byte-compared where exactness is possible and
  envelope-compared where chaos makes it honest.

## The engineering tail (state probed 2026-06-11)

The hygiene findings from today's cold-start probes, so the headline work
above doesn't silently inherit them:

- **`test-project` cannot build**: its spago workspace path-depends on
  `../../visualisation libraries/purescript-psd3-*`, which no longer exists
  (psd3 → hylograph rename/move), and pins registry set 57.1.0 (Jurist is
  on 77.5.0). Fix: strip the demo deps out of the conformance project
  entirely — differential test modules must be foreign-free and
  demo-free (Jurist ADR-0004); demos live in `examples/`.
- **Committed `output-py-new` is stale and broken**: `main` crashes with
  `fromStringImpl() takes 1 positional argument but 4 were given` (FFI
  arity drift), and the `Test.CrossBackend.*` sources were never
  regenerated into it.
- **The differential suite exists but is embryonic and unrunnable** — 5
  modules diffing stdout (the right idea, independently arrived at) vs
  Jurist's 426 tests with a curated `KNOWN_DIVERGENCES` ledger. The move:
  adopt Jurist's suite mechanism — ideally *share the same `Test.*`
  corpus* across purejl and purepy so the family has one conformance kit
  and per-backend divergence ledgers (purepy's will include the UTF-16
  set already audited in `UTF16-STRING-AUDIT.md`).
- **Two compilers in one repo, undecided**: the Haskell CoreFn→Python
  generator (`src/`, most recent codegen work) and the
  backend-optimizer-based PureScript one (`backend-python/`, has Asyncio +
  tailRec directives). Jurist has exactly one binary. This wants ADR-0001
  of a new `docs/design-decisions/` (family format, per Jurist /
  backend-wasm) before any new codegen work.
- **No ADRs at all** — the existing docs are good implementation notes;
  the decisions inside them (tuple ADTs, platform-native Asyncio-not-Aff,
  accepted UTF-16 divergence) should be backfilled as records once the
  compiler question is settled.

## Suggested order

1. **Settle the compiler ADR** (Haskell vs backend-optimizer) — everything
   else stacks on it. Note `purescript-backend-erl` precedent favors the
   optimizer path; the Haskell path has the recent codegen fixes. Decide,
   record, retire the other.
2. **Resurrect conformance the Jurist way**: clean foreign-free test
   workspace on a current package set, shared `Test.*` corpus, divergence
   ledger (seeded from the UTF-16 audit). This is the evidence backbone —
   nothing above it is claimable without it.
3. **Tier 2, the fourth column**: `python/` workspace in Jurist's
   numexpr-edsl (or a sibling here referencing `core` by path), verbs
   graded per the table above. Smallest step with the largest Polyglot
   payoff; the receipts already exist.
4. **Tier 1** typed numpy handles (proves the region discipline on this
   backend).
5. **Tier 2′** the DuckDB-denoted typed query eDSL — the flagship, and the
   bridge to the home data world.
6. **Tier 3** probes (typed wire contract first), marimo/ShapedSteer when
   the appetite arrives.

Aff↔asyncio (`AFF-ASYNCIO-DESIGN.md`) stays parked as designed: the
platform-native `Control.Monad.Asyncio` choice is validated by every other
backend's experience; it becomes urgent only when Tier-3 services need
structured concurrency, and the design doc is already written.
