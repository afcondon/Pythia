#!/usr/bin/env bash
# Conformance lane for Pythia (purepy) — the mechanical gate for any change to
# the code generator or the foreign catalogue. Mirrors the sibling Jurist
# backend's bin/conformance.sh, whose absence here was recorded as a gap in
# docs/kb/architecture/backend-exhibit-lessons.md.
#
# Two lanes, because they answer different questions:
#
#   1. The DIFFERENTIAL suite — the same FFI-free source on JS and Python,
#      diffed byte-for-byte. Answers "does this mean the same thing on both
#      runtimes?".
#   2. The COMPANION-LIBRARY laws — single-runtime property assertions for
#      Python.Kwargs and whatever joins it. Lane 1 structurally CANNOT cover
#      these: a companion library has no JavaScript counterpart to diff
#      against, so without lane 2 "we have a conformance suite" would imply a
#      coverage it does not have.
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

echo "==> conformance lane GREEN"
