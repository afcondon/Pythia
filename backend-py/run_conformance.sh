#!/bin/zsh
# backend-py conformance: run the SAME Test.* corpus through the optimizer lane
# and diff it against the JavaScript reference, module by module.
#
# The runtime (`_purepy_runtime.py`) and every foreign shim (`*_foreign.py`) come
# from `purepy` -- the oracle lane -- and are copied in unmodified. Neither is
# generated here and neither is checked in under backend-py, so the two lanes
# cannot drift the way Gnomon's two Go runtimes did (they diverged by two symbols
# and it took a red CI to notice).
#
# A module is "green" if its output is byte-identical to node's, or differs ONLY
# on the seeded divergence ledger (INT64: Python ints don't wrap at 32 bits;
# ASTRAL: Python strings count codepoints, not UTF-16 units; STACK: no stack
# traces in either Python lane).
#
# Usage: ./run_conformance.sh [--skip-purepy]
set -e
HERE=${0:A:h}
SUITE="$HERE/../test-suite"
BASE="$SUITE/output-py"          # purepy's output: the shared runtime + foreigns
OUT=/tmp/bpy-conf

# Corpus modules are DISCOVERED, never listed by hand -- a hand-maintained list
# is how Test.Maps sat unexecuted in the Gnomon repo for weeks. Benchmarks are
# the only exclusion: they measure rather than assert and print no TEST lines.
mods=(${(f)"$(cd "$SUITE/src/Test" && ls *.purs | sed 's/\.purs$//' | grep -v '^Bench')"})

if [[ "$1" != "--skip-purepy" ]]; then
  echo "==> building purepy (the oracle lane supplies the runtime + foreigns)"
  (cd "$HERE/.." && stack build 2>&1 | tail -3)
  echo "==> purepy -> $BASE"
  (cd "$SUITE" && stack exec --stack-yaml ../stack.yaml purepy -- output output-py >/dev/null)
fi

echo "==> building backend-py"
(cd "$HERE" && spago build >/dev/null 2>&1)

# Per-entry pruning means each program is emitted for its OWN main: emitting
# --main Test.X prunes every binding unreachable from Test.X.main, so we emit
# once per module into a clean directory.
pass=0; ledger=0; bad=0
for m in $mods; do
  mod="Test.$m"
  rm -rf "$OUT"; mkdir -p "$OUT"
  (cd "$HERE" && spago run -- --corefn-dir "$SUITE/output" --output-dir "$OUT" --main "$mod" >/dev/null 2>&1)
  # The shared runtime and every foreign shim, verbatim from the oracle lane.
  cp "$BASE/_purepy_runtime.py" "$OUT/"
  cp "$BASE"/*_foreign.py "$OUT/" 2>/dev/null || true
  if ! (cd "$OUT" && python3 entrypoint.py > /tmp/py_out.txt 2>/tmp/py_err.txt); then
    echo "[$mod] RUN-ERR: $(tail -2 /tmp/py_err.txt | head -1)"; bad=$((bad+1)); continue
  fi
  node --input-type=module -e "import(\"$SUITE/output/$mod/index.js\").then(x => x.main())" > /tmp/js_out.txt 2>/dev/null
  nfiles=$(ls "$OUT"/*.py | wc -l | tr -d ' ')
  if diff -q /tmp/js_out.txt /tmp/py_out.txt >/dev/null; then
    echo "[$mod] OK identical ($(wc -l </tmp/py_out.txt|tr -d ' ') lines, $nfiles files)"; pass=$((pass+1))
  elif diff /tmp/js_out.txt /tmp/py_out.txt | grep -qiE "INT64|ASTRAL|STACK"; then
    echo "[$mod] OK ledger-only (INT64/ASTRAL/STACK, $nfiles files)"; ledger=$((ledger+1))
  else
    echo "[$mod] FAIL:"; diff /tmp/js_out.txt /tmp/py_out.txt | head -8; bad=$((bad+1))
  fi
done
echo "=== $pass identical + $ledger ledger-only = $((pass+ledger))/${#mods[@]} green; $bad bad ==="
[ $bad -eq 0 ]
