# Embedding Explorer (purepy example)

Typed Flask routes + UMAP projection — PureScript orchestrates, umap-learn
computes. Rebuilt from the first incarnation's flagship demo
(`test-project/src/Demo/EmbeddingExplorer.purs`).

## Run

```bash
cd examples/embedding-explorer
spago build
stack exec --stack-yaml ../../stack.yaml purepy -- output output-py
python3 output-py            # Flask on http://localhost:8081
```

Then open `demo/embedding-explorer.html` in a browser (it fetches
`http://localhost:8081/api/embeddings` — the first request runs the UMAP
fit and takes a few seconds).

Quick smoke test without the browser:

```bash
curl -s http://localhost:8081/ | head
curl -s http://localhost:8081/api/embeddings | python3 -m json.tool | head -30
```

Python dependencies: `flask`, `flask-cors`, `umap-learn`, `numpy`.

## Notes

- FFI shims live in `ffi-py/` and are copied into `output-py/` by purepy
  (user shims win over built-ins).
- `_to_json_safe` in the Flask shim is type-precise on this backend
  (PS Arrays are lists, ADT values are tuples) — the first incarnation
  needed a heuristic that mis-rendered `Array String` as tagged JSON.
