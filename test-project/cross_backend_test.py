#!/usr/bin/env python3
"""
Cross-Backend Test Orchestrator for PureScript Python Backend

Runs the same PureScript test modules on both JS (node) and Python backends,
diffs stdout/stderr/exit codes, and reports divergences.

Usage:
    cd test-project
    python3 cross_backend_test.py

Prerequisites:
    - spago build (generates output/ with JS and corefn.json)
    - purepy output output-py-new (generates Python from CoreFn)
    - node and python3 on PATH

Output:
    - JSONL results to stdout (parseable)
    - Summary table to stderr
    - Exit code 0 if no unexpected divergences
"""

import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import date
from pathlib import Path
from typing import Optional

# Test modules and their JS/Python module paths
TEST_MODULES = [
    {
        "name": "Strings",
        "ps_module": "Test.CrossBackend.Strings",
        "js_module": "Test.CrossBackend.Strings",
        "py_module": "test_cross_backend_strings",
    },
    {
        "name": "Numbers",
        "ps_module": "Test.CrossBackend.Numbers",
        "js_module": "Test.CrossBackend.Numbers",
        "py_module": "test_cross_backend_numbers",
    },
    {
        "name": "ADTs",
        "ps_module": "Test.CrossBackend.ADTs",
        "js_module": "Test.CrossBackend.ADTs",
        "py_module": "test_cross_backend_a_d_ts",
    },
    {
        "name": "Effects",
        "ps_module": "Test.CrossBackend.Effects",
        "js_module": "Test.CrossBackend.Effects",
        "py_module": "test_cross_backend_effects",
    },
    {
        "name": "Arrays",
        "ps_module": "Test.CrossBackend.Arrays",
        "js_module": "Test.CrossBackend.Arrays",
        "py_module": "test_cross_backend_arrays",
    },
]

# Known divergences that are expected (not bugs)
KNOWN_DIVERGENCES = {
    # String CodeUnits: Python uses code points, JS uses code units
    "Strings:length-emoji",
    "Strings:length-two-emoji",
    "Strings:length-mixed-emoji",
    "Strings:charAt-0-emoji",
    "Strings:take-1-emoji",
    "Strings:take-2-emoji",
    "Strings:toCharArray-emoji",
    # Float formatting may differ slightly
    # "Numbers:num-show-large",  # uncomment if 1e10 vs 10000000000.0
}


@dataclass
class RunResult:
    """Result of running a test module on a single backend."""
    backend: str
    module: str
    exit_code: int
    stdout: str
    stderr: str
    duration_ms: float
    error: Optional[str] = None


@dataclass
class TestLine:
    """A single TEST line parsed from stdout."""
    name: str
    value: str


@dataclass
class ComparisonResult:
    """Comparison of a single test line between JS and Python."""
    module: str
    test: str
    js_value: Optional[str]
    py_value: Optional[str]
    match: bool
    known_divergence: bool = False


def run_js_module(module_info: dict) -> RunResult:
    """Run a PureScript module via Node.js."""
    js_module = module_info["js_module"]
    # Node.js require path: output/<Module.Name>/index.js
    js_path = f"./output/{js_module}/index.js"

    if not os.path.exists(js_path):
        return RunResult(
            backend="js",
            module=module_info["name"],
            exit_code=-1,
            stdout="",
            stderr="",
            duration_ms=0,
            error=f"JS module not found: {js_path}",
        )

    cmd = ["node", "-e", f'require("{js_path}").main()']
    start = time.perf_counter()
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
            cwd=os.path.dirname(os.path.abspath(__file__)),
        )
        elapsed = (time.perf_counter() - start) * 1000
        return RunResult(
            backend="js",
            module=module_info["name"],
            exit_code=result.returncode,
            stdout=result.stdout,
            stderr=result.stderr,
            duration_ms=elapsed,
        )
    except subprocess.TimeoutExpired:
        elapsed = (time.perf_counter() - start) * 1000
        return RunResult(
            backend="js",
            module=module_info["name"],
            exit_code=-1,
            stdout="",
            stderr="TIMEOUT",
            duration_ms=elapsed,
            error="Timed out after 30s",
        )
    except Exception as e:
        return RunResult(
            backend="js",
            module=module_info["name"],
            exit_code=-1,
            stdout="",
            stderr=str(e),
            duration_ms=0,
            error=str(e),
        )


def run_py_module(module_info: dict) -> RunResult:
    """Run a PureScript module via Python."""
    py_module = module_info["py_module"]
    py_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output-py-new")

    cmd = [
        sys.executable,
        "-c",
        f"import sys; sys.path.insert(0, '{py_dir}'); import {py_module}; {py_module}.main()",
    ]
    start = time.perf_counter()
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
        )
        elapsed = (time.perf_counter() - start) * 1000
        return RunResult(
            backend="python",
            module=module_info["name"],
            exit_code=result.returncode,
            stdout=result.stdout,
            stderr=result.stderr,
            duration_ms=elapsed,
        )
    except subprocess.TimeoutExpired:
        elapsed = (time.perf_counter() - start) * 1000
        return RunResult(
            backend="python",
            module=module_info["name"],
            exit_code=-1,
            stdout="",
            stderr="TIMEOUT",
            duration_ms=elapsed,
            error="Timed out after 30s",
        )
    except Exception as e:
        return RunResult(
            backend="python",
            module=module_info["name"],
            exit_code=-1,
            stdout="",
            stderr=str(e),
            duration_ms=0,
            error=str(e),
        )


def parse_test_lines(stdout: str) -> dict[str, str]:
    """Parse TEST lines from stdout into a dict of name -> value."""
    tests = {}
    for line in stdout.strip().split("\n"):
        line = line.strip()
        if line.startswith("TEST "):
            rest = line[5:]
            if ": " in rest:
                name, value = rest.split(": ", 1)
                tests[name] = value
    return tests


def compare_results(
    module_name: str, js_result: RunResult, py_result: RunResult
) -> list[ComparisonResult]:
    """Compare JS and Python test outputs line by line."""
    comparisons = []

    # Check for runtime errors
    if js_result.error:
        comparisons.append(
            ComparisonResult(
                module=module_name,
                test="__runtime__",
                js_value=f"ERROR: {js_result.error}",
                py_value=None,
                match=False,
            )
        )
        return comparisons

    if py_result.error:
        comparisons.append(
            ComparisonResult(
                module=module_name,
                test="__runtime__",
                js_value=None,
                py_value=f"ERROR: {py_result.error}",
                match=False,
            )
        )
        return comparisons

    # Check exit codes
    if js_result.exit_code != py_result.exit_code:
        comparisons.append(
            ComparisonResult(
                module=module_name,
                test="__exit_code__",
                js_value=str(js_result.exit_code),
                py_value=str(py_result.exit_code),
                match=False,
            )
        )

    # Parse and compare test lines
    js_tests = parse_test_lines(js_result.stdout)
    py_tests = parse_test_lines(py_result.stdout)

    all_test_names = sorted(set(js_tests.keys()) | set(py_tests.keys()))

    for test_name in all_test_names:
        js_val = js_tests.get(test_name)
        py_val = py_tests.get(test_name)
        match = js_val == py_val
        known = f"{module_name}:{test_name}" in KNOWN_DIVERGENCES

        comparisons.append(
            ComparisonResult(
                module=module_name,
                test=test_name,
                js_value=js_val,
                py_value=py_val,
                match=match,
                known_divergence=known and not match,
            )
        )

    return comparisons


def emit_jsonl(module_name: str, comparisons: list[ComparisonResult]):
    """Emit JSONL results to stdout."""
    for comp in comparisons:
        record = {
            "module": comp.module,
            "test": comp.test,
            "js_value": comp.js_value,
            "py_value": comp.py_value,
            "match": comp.match,
            "known_divergence": comp.known_divergence,
            "date": str(date.today()),
        }
        print(json.dumps(record))


def print_summary(all_comparisons: list[ComparisonResult], file=sys.stderr):
    """Print a human-readable summary table."""
    total = len(all_comparisons)
    matched = sum(1 for c in all_comparisons if c.match)
    known = sum(1 for c in all_comparisons if c.known_divergence)
    unexpected = sum(1 for c in all_comparisons if not c.match and not c.known_divergence)
    missing_js = sum(1 for c in all_comparisons if c.js_value is None)
    missing_py = sum(1 for c in all_comparisons if c.py_value is None)

    print("\n" + "=" * 70, file=file)
    print("Cross-Backend Test Summary", file=file)
    print("=" * 70, file=file)
    print(f"  Total tests:             {total}", file=file)
    print(f"  Matched:                 {matched}", file=file)
    print(f"  Known divergences:       {known}", file=file)
    print(f"  UNEXPECTED divergences:  {unexpected}", file=file)
    print(f"  Missing in JS:           {missing_js}", file=file)
    print(f"  Missing in Python:       {missing_py}", file=file)
    print("=" * 70, file=file)

    # Show divergences
    divergences = [c for c in all_comparisons if not c.match]
    if divergences:
        print("\nDivergences:", file=file)
        print(f"  {'Module':<12} {'Test':<30} {'JS':<25} {'Python':<25} {'Known'}", file=file)
        print(f"  {'-'*12} {'-'*30} {'-'*25} {'-'*25} {'-'*5}", file=file)
        for c in divergences:
            js_display = (c.js_value or "<missing>")[:24]
            py_display = (c.py_value or "<missing>")[:24]
            known_mark = "yes" if c.known_divergence else "NO"
            print(
                f"  {c.module:<12} {c.test:<30} {js_display:<25} {py_display:<25} {known_mark}",
                file=file,
            )

    # Per-module summary
    print("\nPer-module results:", file=file)
    modules = {}
    for c in all_comparisons:
        if c.module not in modules:
            modules[c.module] = {"total": 0, "match": 0, "known": 0, "unexpected": 0}
        modules[c.module]["total"] += 1
        if c.match:
            modules[c.module]["match"] += 1
        elif c.known_divergence:
            modules[c.module]["known"] += 1
        else:
            modules[c.module]["unexpected"] += 1

    print(f"  {'Module':<12} {'Total':<8} {'Match':<8} {'Known':<8} {'Unexpected'}", file=file)
    print(f"  {'-'*12} {'-'*8} {'-'*8} {'-'*8} {'-'*10}", file=file)
    for mod, stats in sorted(modules.items()):
        status = "PASS" if stats["unexpected"] == 0 else "FAIL"
        print(
            f"  {mod:<12} {stats['total']:<8} {stats['match']:<8} {stats['known']:<8} {stats['unexpected']:<10} {status}",
            file=file,
        )

    print(file=file)
    if unexpected == 0:
        print("RESULT: All tests passed (divergences are known/expected)", file=file)
    else:
        print(f"RESULT: {unexpected} UNEXPECTED divergence(s) found", file=file)

    return unexpected == 0


def main():
    print("# Cross-Backend Test Results", file=sys.stderr)
    print(f"# Date: {date.today()}", file=sys.stderr)
    print(f"# Modules: {len(TEST_MODULES)}", file=sys.stderr)
    print(file=sys.stderr)

    all_comparisons = []

    for module_info in TEST_MODULES:
        name = module_info["name"]
        print(f"Running {name}...", file=sys.stderr, end=" ", flush=True)

        js_result = run_js_module(module_info)
        py_result = run_py_module(module_info)

        print(
            f"JS: {js_result.duration_ms:.0f}ms, Py: {py_result.duration_ms:.0f}ms",
            file=sys.stderr,
        )

        if js_result.stderr and not js_result.error:
            print(f"  JS stderr: {js_result.stderr[:200]}", file=sys.stderr)
        if py_result.stderr and not py_result.error:
            print(f"  Py stderr: {py_result.stderr[:200]}", file=sys.stderr)

        comparisons = compare_results(name, js_result, py_result)
        all_comparisons.extend(comparisons)

        # Emit JSONL to stdout
        emit_jsonl(name, comparisons)

    success = print_summary(all_comparisons)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
