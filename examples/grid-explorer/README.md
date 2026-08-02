# Grid Explorer (purepy example)

**PureScript expresses the analysis; pandapower does the physics.**

N-1 contingency, cascading-failure simulation and topology metrics over the
IEEE 30-bus reference case. The loops, the classification, the graph search and
the arithmetic are all PureScript. The only thing behind a `foreign import` is
one call: *solve this network*.

## Layout

Follows `polyglot-template`'s program axis — one shared core, per-runtime
columns:

```
core/src/
  Grid/Types.purs        vocabulary; Severity ADT             FFI-free
  Grid/Severity.purs     the violation rule                   FFI-free
  Grid/Graph.purs        BFS, components, degree, diameter    FFI-free
  Grid/Contingency.purs  the N-1 loop                         FFI-free
  Grid/Cascade.purs      trip, re-solve, repeat               FFI-free
  Grid/Metrics.purs      topology + loading metrics           FFI-free
  Grid/Solver.purs       THE SEAM — one foreign import
  Server/Flask.purs      the HTTP binding
columns/python/
  spago.yaml             the whole recipe: backend cmd:"true"
  src/Main.purs          routes
  ffi-py/                the per-runtime foreigns
```

Everything above the seam is FFI-free on purpose: those modules compile under
the stock JavaScript backend too, which is what would make a differential
parity column possible (as `stability-atlas` runs `parity-node` against
`parity-jl`).

## Run

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

cd columns/python
spago build
stack exec --stack-yaml ../../../../stack.yaml purepy -- output output-py
../../.venv/bin/python output-py          # Flask on http://localhost:3033
```

Port 3033 matches hypo-punter's docker-compose table, so the `ge-website`
frontend works against this server unchanged. The frontend lives there, not
here — this example is the API server only.

## Endpoints

```bash
curl -s 'localhost:3033/api/network?loadFactor=0.7'      # solved state
curl -s 'localhost:3033/api/contingency?loadFactor=0.7'  # N-1 over every branch
curl -s 'localhost:3033/api/metrics?loadFactor=0.7'      # topology + loading
curl -s -X POST localhost:3033/api/simulate \
  -H 'Content-Type: application/json' \
  -d '{"initialFailures": [35], "loadFactor": 0.7}'      # cascade
```

## What it shows, and how to check it

At the default operating point — **case30 at load factor 0.7** — N-1 returns
**4 critical, 8 warning, 29 safe** across 41 branches. Taking out line 35
cascades: lines 30, 32 and 34 trip and buses 24, 25, 26, 28 and 29 island in
round 0; three lines lost, 11.55 MW shed, and the cascade settles.

None of that is asserted on trust. `native/` holds a **second implementation of
the same analysis with no PureScript in it at all** — straight pandapower,
networkx and numpy — and `native/compare.py` runs both and diffs every field:

```bash
python3 native/compare.py          # correctness + the four performance ratios
python3 native/compare.py --json   # machine-readable
```

All three scenarios currently agree field-for-field, including all 41
contingency cases across 7 fields each and all 16 metric fields, to 1e-9.

- **The power flow balances.** Generation 133.73 − load 132.44 = 1.29 MW, the
  reported losses.
- **The graph metrics match networkx.** avgDegree 2.733, maxDegree 7,
  diameter 6, one component — the reference computes these with `nx.diameter`
  and friends, and the PureScript agrees.

### The reference has already earned its keep

The cascade above used to report **seven** lines lost over two rounds, and this
README said so. It was wrong, and no smoke test could have caught it because
the exhibit produced a plausible cascading picture either way.

Once a round islands part of the network, the closed branches inside that
island have no defined flow, and pandapower says so by reporting NaN. That NaN
crossed the seam into PureScript, where **`nan > 100.0` evaluates to `true`** —
`Ord Number` is `unsafeCompare`, which tries `<`, then `==`, and answers `GT`
for anything it cannot order. This is upstream PureScript semantics, identical
on the JavaScript backend; not a purepy divergence, and it was verified as such
rather than assumed.

So every de-energised branch read as "over its thermal rating" and the cascade
tripped it. The fix is in two places, both of which are now stated contracts:
the seam substitutes a defined value and sets an `energised` flag (see
`_num` in `Grid_Solver_foreign.py`), and the core filters on that flag rather
than trusting a comparison (`Grid.Types.inServiceLines`).

The same NaNs were also travelling to the browser as bare `NaN` tokens, which
are not valid JSON — `JSON.parse` rejects them. `compare.py` now parses every
response with `parse_constant` set to raise, so that cannot come back.

### What the architecture costs

Four ratios rather than one number, because they call for different fixes.
Median of three runs, M4 MBP, case30 at load factor 0.7:

| scenario | architecture tax | structural distortion | displaced compute | seam cost |
|---|---:|---:|---:|---:|
| contingency (42 solves) | 1.22x | **1.03x** | 0.7 % | 8.1 % |
| metrics (1 solve) | 4.45x | **0.98x** | 81.9 % | 1.4 % |
| cascade (2 solves) | 1.37x | **1.07x** | 30.8 % | 6.9 % |

Run `native/compare.py` to regenerate this table; the numbers move a few
percent between runs, so read the shape rather than the third digit.

**Structural distortion is the number that matters and it is ~1.0 across the
board.** It is `poly_foreign / native_foreign`: time inside pandapower here
against time inside pandapower there, for the same answer. At 1.0 the seam did
not deform the computation — we call the library exactly as well as the
single-language version does. That is the failure mode no in-process profiler
can see, because a deformed computation makes foreign *share* rise and so reads
as "clean architecture, the library dominates".

#### Most of the tax was authoring quality, not architecture

The first measurement read **1.85x** on contingency with **44.7 % seam cost**,
and it was tempting to call that the price of having a boundary. It was not.
Per solve, against ~18 ms of actual `runpp`:

```
per-bus load lookup      3.15 ms   a pandas boolean mask PER BUS
_rating_mva per line     0.98 ms   scalar .at lookup for a constant
.iterrows() loops        0.85 ms   the classic pandas anti-pattern
deepcopy of the net      5.40 ms   the independence guarantee
```

The first three are pure waste. Identity, topology, geometry and thermal
ratings are properties of the network, not of a power flow over it, and were
being recomputed on all 42 solves. They now live in `_static()`, computed once
per case and joined onto each solve's results, with result columns read as
numpy arrays instead of walked with `.iterrows()`. **Marshal 9.15 ms ->
1.33 ms**, and byte-identical output — checked against the previous
implementation over six specs spanning case14, case30 and case57.

The deepcopy went differently. `Grid.Solver`'s guarantee — no mutable handle
crosses the boundary, so solves cannot depend on their order — is a property of
the **interface**; copying was one way to obtain it, never the guarantee
itself. The seam now keeps one working network and resets only the columns a
`SolveSpec` can touch. `INDEPENDENCE = "restore" | "copy"` selects either, and
the claim is proven rather than asserted:

```bash
python3 native/compare.py --check-independence
  PASS  restore == copy, spec by spec (45 specs)
  PASS  N-1 sweep forward == reversed
  PASS  N-1 sweep forward == shuffled
  PASS  survives interleaving with other cases/specs
```

Contingency went **1.85x -> 1.22x** and seam cost **44.7 % -> 8.1 %** with no
change to the interface and no change to a single output value. So the polyglot
penalty here was roughly 85 % authoring quality and 15 % architecture — which
is good news, because authoring quality is the fixable kind, and a warning,
because nothing in the type system or the FFI-free-core rule says *you
recomputed the thermal ratings forty-two times*. Only the measurement said it.

#### What is left, and why metrics is different

**Metrics' 4.45x barely moved, correctly.** It was never seam cost: 82 % of it
is PureScript walking a 30-node graph where the reference calls networkx. That
is the exhibit's actual claim — that degree and diameter arithmetic is *our*
analysis, not domain expertise to be borrowed — so it is the price of a
position, not a defect. 4.45x of 23 ms. Report it, never gate on it.

Contingency's residual 22 % is ~1.6 ms per solve marshalling ~1,000 records for
an analysis that reads four scalars from them. A narrower seam operation would
recover part of it; at this size it is not worth a second entry point.

None of these is a "PureScript is slow" result. The one measurement that would
have been is the one that came out clean.

## Why case30, and why a load factor

Two things were wrong with this exhibit before, both easy to reintroduce.

**case14's thermal ratings are placeholders.** Every line reports the same
9900 MVA, reverse-engineered from a `max_i_ka` of 42 kA at 135 kV — and 27,479 kA
at 0.2 kV. Against flows of ~100 MW that is roughly 1 % loading, so no
contingency could ever cross a threshold: the exhibit returned 15 safe out of
15, always. case30 ships six distinct, real ratings, which is the whole
difference between an analysis and a green light.

**`loadFactor` was accepted and ignored.** It appeared in this README's own
smoke test and nowhere in the code; four different load factors returned
byte-identical output. It now scales `p_mw`/`q_mvar` before the solve, and it
is what makes the exhibit an experiment: case30 is comfortable at 0.6,
marginal by 0.8, and has a line over its rating at 1.0.

## Known limitation

`Grid/Graph.purs` wants `Data.Map` and cannot have it: purepy miscompiles the
recursive local binding in `Data.Map.Internal`, so importing it kills the
program at import time. Adjacency is an association array and membership is a
linear scan — free at this size, but the wrong interface. See
`docs/RECURSIVE-LET-BINDING-ISSUE.md`.

Python dependencies: `flask`, `flask-cors`, `pandapower`, `networkx`, `numpy`.
