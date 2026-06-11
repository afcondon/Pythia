# Grid Explorer (purepy example)

Typed Flask routes over **pandapower** — AC power flow, N-1 contingency
analysis, and cascading-failure simulation on the IEEE test cases.
Rebuilt from the first incarnation's showcase
(`purescript-hylograph-showcases/hypo-punter/ge-server`).

## Run

```bash
cd examples/grid-explorer
spago build
stack exec --stack-yaml ../../stack.yaml purepy -- output output-py
python3 output-py            # Flask on http://localhost:8082
```

(Port moved from the original 3022 → 8082: SDI binds 3022 locally. 8082
matches hypo-punter's docker-compose table, so the `ge-website` frontend
should work against this server unchanged.)

Smoke tests:

```bash
curl -s http://localhost:8082/api/network | python3 -m json.tool | head -20
curl -s http://localhost:8082/api/contingency | python3 -m json.tool | head -20
curl -s http://localhost:8082/api/metrics | python3 -m json.tool | head -20
curl -s -X POST http://localhost:8082/api/simulate \
  -H 'Content-Type: application/json' \
  -d '{"initialFailures": [3], "loadFactor": 1.2, "maxIterations": 10}' \
  | python3 -m json.tool | head -20
```

Verified values for case14: power flow converges with 272.4 MW generation,
259.0 MW load, 13.39 MW losses; 15 N-1 contingency cases.

Python dependencies: `flask`, `flask-cors`, `pandapower`, `numpy`.

## Notes

- FFI shims live in `ffi-py/`; `Grid_Cascade_foreign.py` cross-imports a
  helper from `Grid_PowerFlow_foreign.py` (fixed from the old package
  layout).
- The frontend lives in hypo-punter (`ge-website`), not here — this
  example is the API server only.
