#!/usr/bin/env python3
"""
Cross-Backend Benchmark Harness for PureScript Python Backend

Runs the same PureScript benchmarks on both JS (node) and Python, compares
performance, and produces structured output for tracking over time.

Usage:
    cd test-project
    python3 bench/cross_backend_bench.py

Output:
    - JSONL to stdout (append to bench/results/history.jsonl)
    - Comparison table to stderr
"""

import json
import os
import subprocess
import sys
import time
from datetime import date
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
TEST_PROJECT = SCRIPT_DIR.parent
RESULTS_DIR = SCRIPT_DIR / "results"


def ensure_results_dir():
    """Create results directory if it doesn't exist."""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def run_js_benchmark(benchmark_name: str, js_expr: str, iterations: int = 3) -> dict:
    """Run a benchmark via Node.js and return timing info."""
    # Build a self-timing JS snippet
    js_code = f"""
const bench = require('./output/Bench/index.js');
const iterations = {iterations};
const times = [];
for (let i = 0; i < iterations; i++) {{
    const start = process.hrtime.bigint();
    const result = {js_expr};
    const end = process.hrtime.bigint();
    times.push(Number(end - start) / 1e6);
}}
const avg = times.reduce((a, b) => a + b) / times.length;
const min = Math.min(...times);
console.log(JSON.stringify({{
    benchmark: "{benchmark_name}",
    backend: "js",
    avg_ms: avg,
    min_ms: min,
    iterations: iterations,
    times: times
}}));
"""
    try:
        result = subprocess.run(
            ["node", "-e", js_code],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(TEST_PROJECT),
        )
        if result.returncode != 0:
            return {
                "benchmark": benchmark_name,
                "backend": "js",
                "error": result.stderr[:200],
            }
        return json.loads(result.stdout.strip())
    except subprocess.TimeoutExpired:
        return {"benchmark": benchmark_name, "backend": "js", "error": "TIMEOUT"}
    except Exception as e:
        return {"benchmark": benchmark_name, "backend": "js", "error": str(e)}


def run_py_benchmark(benchmark_name: str, py_expr: str, iterations: int = 3) -> dict:
    """Run a benchmark via Python and return timing info."""
    py_code = f"""
import sys, time, json
sys.path.insert(0, 'output-py-new')
import bench

iterations = {iterations}
times = []
for i in range(iterations):
    start = time.perf_counter()
    result = {py_expr}
    end = time.perf_counter()
    times.append((end - start) * 1000)

avg = sum(times) / len(times)
min_t = min(times)
print(json.dumps({{
    "benchmark": "{benchmark_name}",
    "backend": "python",
    "avg_ms": avg,
    "min_ms": min_t,
    "iterations": iterations,
    "times": times
}}))
"""
    try:
        result = subprocess.run(
            [sys.executable, "-c", py_code],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(TEST_PROJECT),
        )
        if result.returncode != 0:
            return {
                "benchmark": benchmark_name,
                "backend": "python",
                "error": result.stderr[:200],
            }
        return json.loads(result.stdout.strip())
    except subprocess.TimeoutExpired:
        return {"benchmark": benchmark_name, "backend": "python", "error": "TIMEOUT"}
    except Exception as e:
        return {"benchmark": benchmark_name, "backend": "python", "error": str(e)}


# Benchmark definitions: (name, js_expr, py_expr)
BENCHMARKS = [
    (
        "fib30",
        "bench.fib(30)",
        "bench.fib(30)",
    ),
    (
        "tree_sum_15",
        "bench.sumTree(bench.buildTree(15))",
        "bench.sumTree(bench.buildTree(15))",
    ),
    (
        "apply_inc_100",
        "bench.applyN(bench.inc)(100)(0)",
        "bench.applyN(bench.inc)(100)(0)",
    ),
    (
        "sumTo_100",
        "bench.sumTo(0)(100)",
        "bench.sumTo(0)(100)",
    ),
]


def run_hand_written_python(benchmark_name: str, iterations: int = 3) -> dict:
    """Run hand-written Python equivalents for baseline comparison."""
    py_code = f"""
import time, json

def fib(n):
    if n <= 1: return n
    return fib(n-1) + fib(n-2)

class Leaf:
    def __init__(self, v): self.value = v
class Branch:
    def __init__(self, l, r): self.left, self.right = l, r

def build_tree(n):
    if n == 0: return Leaf(1)
    return Branch(build_tree(n-1), build_tree(n-1))

def sum_tree(t):
    if isinstance(t, Leaf): return t.value
    return sum_tree(t.left) + sum_tree(t.right)

def apply_n(f, n, x):
    for _ in range(n): x = f(x)
    return x

def sum_to(acc, n):
    while n > 0: acc += n; n -= 1
    return acc

benchmarks = {{
    "fib30": lambda: fib(30),
    "tree_sum_15": lambda: sum_tree(build_tree(15)),
    "apply_inc_100": lambda: apply_n(lambda x: x+1, 100, 0),
    "sumTo_100": lambda: sum_to(0, 100),
}}

name = "{benchmark_name}"
if name in benchmarks:
    iterations = {iterations}
    times = []
    for i in range(iterations):
        start = time.perf_counter()
        result = benchmarks[name]()
        end = time.perf_counter()
        times.append((end - start) * 1000)
    avg = sum(times) / len(times)
    min_t = min(times)
    print(json.dumps({{
        "benchmark": name,
        "backend": "python_native",
        "avg_ms": avg,
        "min_ms": min_t,
        "iterations": iterations,
        "times": times
    }}))
"""
    try:
        result = subprocess.run(
            [sys.executable, "-c", py_code],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            return {
                "benchmark": benchmark_name,
                "backend": "python_native",
                "error": result.stderr[:200],
            }
        return json.loads(result.stdout.strip())
    except Exception as e:
        return {
            "benchmark": benchmark_name,
            "backend": "python_native",
            "error": str(e),
        }


def format_ms(val):
    """Format a millisecond value for display."""
    if isinstance(val, str):
        return val
    if val < 0.01:
        return f"{val*1000:.1f}us"
    if val < 1:
        return f"{val:.3f}ms"
    if val < 1000:
        return f"{val:.1f}ms"
    return f"{val/1000:.2f}s"


def main():
    ensure_results_dir()

    print("# Cross-Backend Benchmark Results", file=sys.stderr)
    print(f"# Date: {date.today()}", file=sys.stderr)
    print(f"# Python: {sys.version.split()[0]}", file=sys.stderr)
    print(file=sys.stderr)

    all_results = []
    today = str(date.today())

    for name, js_expr, py_expr in BENCHMARKS:
        print(f"Running {name}...", file=sys.stderr, end=" ", flush=True)

        js_result = run_js_benchmark(name, js_expr)
        py_result = run_py_benchmark(name, py_expr)
        native_result = run_hand_written_python(name)

        print("done", file=sys.stderr)

        # Add metadata
        for r in [js_result, py_result, native_result]:
            r["date"] = today

        all_results.append((name, js_result, py_result, native_result))

        # Emit JSONL to stdout
        print(json.dumps(js_result))
        print(json.dumps(py_result))
        print(json.dumps(native_result))

    # Print comparison table
    print(file=sys.stderr)
    print("=" * 90, file=sys.stderr)
    print("Cross-Backend Benchmark Comparison", file=sys.stderr)
    print("=" * 90, file=sys.stderr)
    header = f"  {'Benchmark':<20} {'JS (node)':<14} {'PurePy':<14} {'Native Py':<14} {'Py/JS':<10} {'Py/Native':<10}"
    print(header, file=sys.stderr)
    print(f"  {'-'*20} {'-'*14} {'-'*14} {'-'*14} {'-'*10} {'-'*10}", file=sys.stderr)

    for name, js_r, py_r, native_r in all_results:
        js_ms = js_r.get("avg_ms", "err")
        py_ms = py_r.get("avg_ms", "err")
        native_ms = native_r.get("avg_ms", "err")

        js_str = format_ms(js_ms) if isinstance(js_ms, (int, float)) else "ERROR"
        py_str = format_ms(py_ms) if isinstance(py_ms, (int, float)) else "ERROR"
        native_str = (
            format_ms(native_ms) if isinstance(native_ms, (int, float)) else "ERROR"
        )

        ratio_js = ""
        if isinstance(py_ms, (int, float)) and isinstance(js_ms, (int, float)) and js_ms > 0:
            ratio_js = f"{py_ms / js_ms:.1f}x"

        ratio_native = ""
        if isinstance(py_ms, (int, float)) and isinstance(native_ms, (int, float)) and native_ms > 0:
            ratio_native = f"{py_ms / native_ms:.1f}x"

        print(
            f"  {name:<20} {js_str:<14} {py_str:<14} {native_str:<14} {ratio_js:<10} {ratio_native:<10}",
            file=sys.stderr,
        )

    print("=" * 90, file=sys.stderr)
    print(file=sys.stderr)
    print("Notes:", file=sys.stderr)
    print("  - JS (node): PureScript compiled to JavaScript, run on Node.js", file=sys.stderr)
    print("  - PurePy: PureScript compiled to Python via purepy backend", file=sys.stderr)
    print("  - Native Py: Hand-written Python equivalent", file=sys.stderr)
    print("  - Py/JS: PurePy overhead vs JS reference backend", file=sys.stderr)
    print("  - Py/Native: PurePy overhead vs hand-written Python", file=sys.stderr)
    print(file=sys.stderr)

    # Append to history file
    history_file = RESULTS_DIR / "history.jsonl"
    try:
        with open(history_file, "a") as f:
            for name, js_r, py_r, native_r in all_results:
                f.write(json.dumps(js_r) + "\n")
                f.write(json.dumps(py_r) + "\n")
                f.write(json.dumps(native_r) + "\n")
        print(f"Results appended to {history_file}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: could not write to {history_file}: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
