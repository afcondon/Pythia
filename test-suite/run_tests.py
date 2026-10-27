#!/usr/bin/env python3
"""
Cross-backend differential test runner for purescript-python (purepy).

The Test.* corpus is shared with the sibling Jurist backend
(../../purescript-julia/test-suite/src) — one family conformance kit,
per-backend divergence ledgers.

Builds the test modules once with `purs --codegen corefn,js` (via spago),
generates Python with purepy, then runs every Test.* module on BOTH
backends and diffs their TEST lines:

    TEST <name>: <value>

A test passes when the JS backend (the reference semantics) and the
Python backend print byte-identical values, or when it is an entry of
divergences.json and both print exactly the values recorded there (see
ledger.py). A ledger entry that stops being true fails the run as STALE.

Expected generated layout (the spec the new compiler compiles to):
    output-py/<Module_Name>.py     one module per PS module,
                                   dots -> underscores, case preserved
    `main` is an Effect (a zero-arg callable); running a module is
    importing it and calling `main()`.

Usage:
    cd test-suite
    python3 run_tests.py              # build + run everything
    python3 run_tests.py --skip-build # reuse existing output/ + output-py/
    python3 run_tests.py Strings      # only modules matching a substring

Exit code: 0 iff no unexpected divergences and no module-level errors.
"""

import argparse
import subprocess
import sys
from pathlib import Path

import ledger

HERE = Path(__file__).resolve().parent

# Modules are DISCOVERED from src/Test/, never listed by hand.
#
# A hand-maintained list is the runner-completeness hazard: a module gets
# written, never added to the list, and the suite reports green over source it
# has not compiled. That is exactly how Test.Maps sat unexecuted in the Gnomon
# corpus, and how one module went unlisted here. Discovery makes adding a
# corpus module a one-file operation and makes skipping one impossible by
# accident.
#
# Only deliberate exclusions are named, and each one has to say why.
EXCLUDED_MODULES = {
    # Benchmarks: they measure rather than assert, print no TEST lines, and
    # their runtime would dominate the lane. They belong to the performance
    # lane, not the differential one.
    "Test.BenchFib",
    "Test.BenchFold",
    "Test.BenchLocal",
    "Test.BenchLoop",
}


def discover_test_modules():
    found = sorted(
        f"Test.{p.stem}" for p in (HERE / "src" / "Test").glob("*.purs")
    )
    if not found:
        sys.exit("no Test.*.purs found under src/Test — wrong working directory?")
    return [m for m in found if m not in EXCLUDED_MODULES]


TEST_MODULES = discover_test_modules()

# Deliberate divergences live in divergences.json, with BOTH values and a
# cause, and are judged by ledger.py -- the same judge the optimizer lane uses.
# A name alone used to be enough to pass a ledgered test whatever it printed.
LEDGER = ledger.load("purepy")



def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=HERE, **kw)


def build():
    # Ensure dependency sources are materialized under .spago/p. On a fresh
    # checkout `spago sources` only prints globs; `spago build` is what fetches
    # and unpacks the packages those globs point at. (Its JS output is unused —
    # the corefn,js compile below regenerates everything.) Locally this is a
    # no-op once deps are present; on CI it is what makes the globs resolve.
    print("• materializing deps (spago build)...", file=sys.stderr)
    r = sh(["spago", "build"])
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit(f"spago build failed ({r.returncode})")
    # spago won't forward --codegen, so resolve the source globs through
    # `spago sources` and drive purs directly with both codegen targets.
    print("• resolving sources (spago)...", file=sys.stderr)
    r = sh(["spago", "sources"])
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit(f"spago sources failed ({r.returncode})")
    globs = r.stdout.split()
    print("• purs compile --codegen corefn,js...", file=sys.stderr)
    r = sh(["purs", "compile", "--codegen", "corefn,js"] + globs)
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit(f"purs compile failed ({r.returncode})")
    print("• purepy output -> output-py...", file=sys.stderr)
    r = sh(["stack", "exec", "--stack-yaml", "../stack.yaml", "purepy", "--",
            "output", "output-py"])
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit(f"purepy failed ({r.returncode})")
    for line in r.stdout.splitlines():
        if "Warning" in line:
            print("  " + line, file=sys.stderr)


def run_js(module):
    path = f"./output/{module}/index.js"
    if not (HERE / path).exists():
        return None, f"missing {path}"
    r = sh(["node", "--input-type=module", "-e",
            f'import("{path}").then(m => m.main())'], timeout=120)
    if r.returncode != 0:
        return None, f"node exit {r.returncode}: {r.stderr.strip()[:300]}"
    return r.stdout, None


def run_python(module):
    py_mod = module.replace(".", "_")
    r = sh([sys.executable, "-c",
            f'import sys; sys.path.insert(0, "output-py"); '
            f'import {py_mod}; {py_mod}.main()'], timeout=300)
    if r.returncode != 0:
        return None, f"python exit {r.returncode}: {r.stderr.strip()[:300]}"
    return r.stdout, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("filter", nargs="?", default="")
    ap.add_argument("--skip-build", action="store_true")
    args = ap.parse_args()

    if not args.skip_build:
        build()

    modules = [m for m in TEST_MODULES if args.filter.lower() in m.lower()]
    total = passed = known = 0
    bad = []
    errors = []

    for mod in modules:
        js_out, js_err = run_js(mod)
        py_out, py_err = run_python(mod)
        if js_err or py_err:
            errors.append((mod, js_err or py_err))
            print(f"{mod}: ERROR {js_err or py_err}", file=sys.stderr)
            continue
        v = LEDGER.judge(mod, js_out, py_out)
        for line in v.lines("python"):
            print(line, file=sys.stderr)
        total += v.total
        passed += v.identical
        known += len(v.known)
        if not v.ok:
            bad.append(mod)
        print(f"{mod}: {v.identical} identical, {len(v.known)} ledgered, "
              f"{len(v.fail) + len(v.mismatch)} fail"
              + (f", {len(v.stale)} stale" if v.stale else ""), file=sys.stderr)

    # Only a full run can say an entry's module has left the corpus.
    if not args.filter:
        for m, t in LEDGER.unvisited(TEST_MODULES):
            bad.append(m)
            print(f"  STALE     {m}/{t}: module is not in the corpus"
                  f" — remove it from divergences.json", file=sys.stderr)

    print(f"\n{passed}/{total} identical, {known} known divergences "
          f"(values checked), {len(bad)} modules failing, "
          f"{len(errors)} module errors", file=sys.stderr)
    sys.exit(0 if not bad and not errors else 1)

if __name__ == "__main__":
    main()
