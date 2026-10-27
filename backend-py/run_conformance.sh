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
# on entries of the divergence ledger (test-suite/divergences.json), with
# exactly the values recorded there. The judge is test-suite/ledger.py, the
# same one the oracle lane uses, so the two lanes cannot disagree about what
# counts as a known divergence.
#
# Usage: ./run_conformance.sh [--skip-purepy]
set -e
HERE=${0:A:h}
SUITE="$HERE/../test-suite"
BASE="$SUITE/output-py"          # purepy's output: the shared runtime + foreigns
# Scratch paths are PER RUN, not fixed. All three optimizer lanes previously
# wrote /tmp/js_out.txt, so running two of them at once silently crossed their
# reference output and produced diffs full of another module's tests — three
# invented failures that looked exactly like real regressions. A gate whose
# result depends on what else is running is not a gate.
TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
OUT="$TMPD/out"

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
# Not silenced. It was, and against an optimizer whose API had moved the build
# failed, `spago run` below ran whatever stale output/ it found, and the lane
# reported on a program nobody had built (review X7).
(cd "$HERE" && spago build)

# Per-entry pruning means each program is emitted for its OWN main: emitting
# --main Test.X prunes every binding unreachable from Test.X.main, so we emit
# once per module into a clean directory.
pass=0; ledger=0; bad=0
for m in $mods; do
  mod="Test.$m"
  rm -rf "$OUT"; mkdir -p "$OUT"
  # The emit step and the JS reference step are guarded rather than bare. Both
  # used to run under `set -e` with their output silenced, so a failure in
  # either killed the whole lane mid-loop having printed NOTHING about it — the
  # log simply stopped after the previous module's OK line. That is a gate that
  # can fail invisibly, which is the same fault as a gate that passes
  # invisibly. Report it against the module, count it bad, keep going.
  if ! (cd "$HERE" && spago run -- --corefn-dir "$SUITE/output" --output-dir "$OUT" --main "$mod" >/dev/null 2>"$TMPD/emit_err.txt"); then
    echo "[$mod] EMIT-ERR: $(grep -v '^$' "$TMPD/emit_err.txt" | tail -1 | head -c 160)"; bad=$((bad+1)); continue
  fi
  # The shared runtime and every foreign shim, verbatim from the oracle lane.
  cp "$BASE/_purepy_runtime.py" "$OUT/"
  cp "$BASE"/*_foreign.py "$OUT/" 2>/dev/null || true
  if ! (cd "$OUT" && python3 entrypoint.py > "$TMPD/py_out.txt" 2>"$TMPD/py_err.txt"); then
    echo "[$mod] RUN-ERR: $(tail -2 "$TMPD/py_err.txt" | head -1)"; bad=$((bad+1)); continue
  fi
  if ! node --input-type=module -e "import(\"$SUITE/output/$mod/index.js\").then(x => x.main())" > "$TMPD/js_out.txt" 2>"$TMPD/js_err.txt"; then
    echo "[$mod] JSREF-ERR: $(grep -v '^$' "$TMPD/js_err.txt" | tail -1 | head -c 160)"; bad=$((bad+1)); continue
  fi
  nfiles=$(ls "$OUT"/*.py | wc -l | tr -d ' ')
  # Every TEST line is judged by name against the ledger, with values. The
  # lane used to exempt any diff line matching INT64|ASTRAL|STACK|NEGZERO, so
  # a regression in any test whose NAME carried one of those words passed
  # (review X3 b).
  if verdict="$(python3 "$SUITE/ledger.py" compare --lane backend-py "$mod" "$TMPD/js_out.txt" "$TMPD/py_out.txt")"; then
    if diff -q "$TMPD/js_out.txt" "$TMPD/py_out.txt" >/dev/null; then
      echo "[$mod] OK identical ($(wc -l <"$TMPD/py_out.txt"|tr -d ' ') lines, $nfiles files)"; pass=$((pass+1))
    else
      echo "[$mod] OK ledger-only (${verdict##*RESULT }, $nfiles files)"; ledger=$((ledger+1))
    fi
  else
    echo "[$mod] FAIL:"; echo "$verdict" | grep -v '^  KNOWN' | head -12; bad=$((bad+1))
  fi
done
# An entry whose module has left the corpus is stale on this lane too.
if ! python3 "$SUITE/ledger.py" stale --lane backend-py "${mods[@]/#/Test.}"; then bad=$((bad+1)); fi
echo "=== $pass identical + $ledger ledger-only = $((pass+ledger))/${#mods[@]} green; $bad bad ==="
[ $bad -eq 0 ]
