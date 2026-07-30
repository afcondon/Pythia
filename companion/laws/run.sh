#!/usr/bin/env bash
# The companion-library law lane.
#
# Not part of bin/conformance.sh's differential suite, and deliberately so:
# Python.Kwargs has no JavaScript counterpart, so there is nothing to diff it
# against. These are single-runtime property assertions instead.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$HERE"

spago build
stack exec --stack-yaml "$ROOT/stack.yaml" purepy -- output output-py
out="$(python3 output-py)"
echo "$out"
grep -q "ALL LAWS HOLD" <<<"$out" \
  || { echo "::error::companion-library laws failed"; exit 1; }
