#!/usr/bin/env bash
# Conformance lane for Pythia (purepy) — the mechanical gate for any change to
# the code generator or the foreign catalogue. Mirrors the sibling Jurist
# backend's bin/conformance.sh, whose absence here was recorded as a gap in
# docs/kb/architecture/backend-exhibit-lessons.md.
#
# Pythia has TWO implementations (ADR-0003), and the lanes below answer
# different questions:
#
#   1. The DIFFERENTIAL suite — the same FFI-free source on JS and Python,
#      diffed byte-for-byte, through the ORACLE (`purepy`). Answers "does this
#      mean the same thing on both runtimes?", and is what any correctness
#      claim rests on.
#   2. The COMPANION-LIBRARY laws — single-runtime property assertions for
#      Python.Kwargs and whatever joins it. Lane 1 structurally CANNOT cover
#      these: a companion library has no JavaScript counterpart to diff
#      against, so without lane 2 "we have a conformance suite" would imply a
#      coverage it does not have.
#   3. The OPTIMIZER lane — backend-py/ consuming
#      purescript-backend-optimizer's IR. Same corpus, different path through
#      the compiler.
#   4. The NO-FORK check — backend-py must not carry its own copy of the
#      runtime or of any foreign shim. Gnomon kept two Go runtimes, they
#      diverged by two symbols, and only a red CI found it; the cheap gate is
#      to assert the second copy does not exist.
#
# Neither lane sees the third axis — whether a library needs a foreign this
# backend does not supply. That is the portability index
# (../purescript-julia/bin/portability-index.py).
#
# Prereqs on PATH: stack, purs, spago, node, python3.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> building purepy (stack)"
stack build

echo "==> differential suite (test-suite)"
(
  cd test-suite
  python3 run_tests.py
)

echo "==> companion-library laws (companion/laws)"
out="$(./companion/laws/run.sh)"
grep -q "ALL LAWS HOLD" <<<"$out" \
  || { echo "$out"; echo "::error::companion-library laws failed"; exit 1; }
echo "    $(grep -c '^ok   ' <<<"$out") laws hold"

echo "==> optimizer lane: backend-py over the shared corpus"
if [[ -d ../purescript-backend-optimizer ]]; then
  ( cd backend-py && ./run_conformance.sh --skip-purepy )
else
  echo "    SKIPPED — ../purescript-backend-optimizer not checked out."
  echo "    The optimizer lane needs it as a local sibling (see backend-py/README.md)."
fi

echo "==> no-fork check: backend-py owns no runtime and no foreign shims"
strays="$(find backend-py -name '_purepy_runtime.py' -o -name '*_foreign.py' 2>/dev/null || true)"
if [[ -n "$strays" ]]; then
  echo "$strays"
  echo "::error::backend-py must consume the oracle lane's runtime and shims, not carry copies (ADR-0003)"
  exit 1
fi
echo "    none, as required"

echo "==> conformance lane GREEN"
