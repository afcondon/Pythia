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
../../.venv/bin/python output-py          # Flask on http://localhost:8082
```

Port 8082 matches hypo-punter's docker-compose table, so the `ge-website`
frontend works against this server unchanged. The frontend lives there, not
here — this example is the API server only.

## Endpoints

```bash
curl -s 'localhost:8082/api/network?loadFactor=0.7'      # solved state
curl -s 'localhost:8082/api/contingency?loadFactor=0.7'  # N-1 over every branch
curl -s 'localhost:8082/api/metrics?loadFactor=0.7'      # topology + loading
curl -s -X POST localhost:8082/api/simulate \
  -H 'Content-Type: application/json' \
  -d '{"initialFailures": [35], "loadFactor": 0.7}'      # cascade
```

## What it shows, and how to check it

At the default operating point — **case30 at load factor 0.7** — N-1 returns
**4 critical, 8 warning, 29 safe** across 41 branches. Taking out line 35
cascades: three lines trip and five buses island in round 0, four more trip in
round 1; seven lines lost, 11.5 MW shed.

Every claim is checkable against the library directly:

- **The power flow balances.** Generation 133.73 − load 132.44 = 1.29 MW, the
  reported losses.
- **The graph metrics match networkx.** avgDegree 2.733, maxDegree 7,
  diameter 6, one component — cross-checked against `nx.diameter` and friends.
- **The N-1 counts match a direct pandapower sweep** at the same load factor.

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
