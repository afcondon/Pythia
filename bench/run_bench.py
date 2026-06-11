#!/usr/bin/env python3
"""
Cross-backend benchmark runner for purepy.

Builds bench/src with purs (corefn + js), generates Python with purepy, then
times the same exported workloads three ways:

  - purepy:   the generated Python, called in-process
  - node:     the reference JS backend, timed inside one node process
  - python:   hand-written Python equivalents (the "native" baseline)

Reports min-of-N wall times and the purepy/native overhead factor, next to
the first incarnation's recorded numbers (docs/ROADMAP.md) for the same
workloads at the same scales.

Usage:
    cd bench
    python3 run_bench.py              # build + run
    python3 run_bench.py --skip-build
"""

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent

REPS = {
    "fib(30)": 3,
    "treeSum(depth 15)": 5,
    "applyInc(100)": 200,
    "sumTo(100)": 200,
    "sumTo(1e6)": 3,
}

# The first incarnation's measurements (docs/ROADMAP.md, "Baseline
# Measurements"), milliseconds, for the same workloads/scales.
OLD = {
    "fib(30)": (2714.0, 121.0),       # (old purepy, hand-written)
    "treeSum(depth 15)": (61.0, 19.0),
    "applyInc(100)": (0.20, 0.01),
    "sumTo(100)": (0.18, 0.01),
    "sumTo(1e6)": (None, None),       # old backend: stack overflow
}


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, cwd=HERE, **kw)


def build():
    print("• spago build...", file=sys.stderr)
    r = sh(["spago", "build"])
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit("spago build failed")
    r = sh(["spago", "sources"])
    globs = r.stdout.split()
    print("• purs compile --codegen corefn,js...", file=sys.stderr)
    r = sh(["purs", "compile", "--codegen", "corefn,js"] + globs)
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit("purs compile failed")
    print("• purepy output -> output-py...", file=sys.stderr)
    r = sh(["stack", "exec", "--stack-yaml", "../stack.yaml", "purepy", "--",
            "output", "output-py"])
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        sys.exit("purepy failed")


# ---------------------------------------------------------------- purepy --

def bench_purepy():
    sys.path.insert(0, str(HERE / "output-py"))
    import Bench  # noqa: E402
    sys.setrecursionlimit(200000)
    work = {
        "fib(30)": lambda: Bench.fib(30),
        "treeSum(depth 15)": lambda: Bench.sumTree(Bench.buildTree(15)),
        "applyInc(100)": lambda: Bench.applyInc(100),
        "sumTo(100)": lambda: Bench.sumTo(0)(100),
        "sumTo(1e6)": lambda: Bench.sumTo(0)(1000000),
    }
    return {name: time_min(f, REPS[name]) for name, f in work.items()}


# ---------------------------------------------------------------- native --

def fib_native(n):
    return n if n <= 1 else fib_native(n - 1) + fib_native(n - 2)


def build_tree_native(n):
    return (1,) if n == 0 else (build_tree_native(n - 1), build_tree_native(n - 1))


def sum_tree_native(t):
    return t[0] if len(t) == 1 else sum_tree_native(t[0]) + sum_tree_native(t[1])


def apply_inc_native(n):
    x = 0
    for _ in range(n):
        x += 1
    return x


def sum_to_native(acc, n):
    while n > 0:
        acc += n
        n -= 1
    return acc


def bench_native():
    work = {
        "fib(30)": lambda: fib_native(30),
        "treeSum(depth 15)": lambda: sum_tree_native(build_tree_native(15)),
        "applyInc(100)": lambda: apply_inc_native(100),
        "sumTo(100)": lambda: sum_to_native(0, 100),
        "sumTo(1e6)": lambda: sum_to_native(0, 1000000),
    }
    return {name: time_min(f, REPS[name]) for name, f in work.items()}


# ------------------------------------------------------------------ node --

NODE_SCRIPT = """
import("./output/Bench/index.js").then(B => {
  const reps = %s;
  const work = {
    "fib(30)": () => B.fib(30),
    "treeSum(depth 15)": () => B.sumTree(B.buildTree(15)),
    "applyInc(100)": () => B.applyInc(100),
    "sumTo(100)": () => B.sumTo(0)(100),
    "sumTo(1e6)": () => B.sumTo(0)(1000000),
  };
  const out = {};
  for (const [name, f] of Object.entries(work)) {
    f();  // warmup
    let best = Infinity;
    for (let i = 0; i < reps[name]; i++) {
      const t0 = process.hrtime.bigint();
      f();
      const ms = Number(process.hrtime.bigint() - t0) / 1e6;
      if (ms < best) best = ms;
    }
    out[name] = best;
  }
  console.log(JSON.stringify(out));
});
"""


def bench_node():
    r = sh(["node", "--input-type=module", "-e", NODE_SCRIPT % json.dumps(REPS)],
           timeout=300)
    if r.returncode != 0:
        sys.exit(f"node bench failed: {r.stderr[:400]}")
    return json.loads(r.stdout.strip().splitlines()[-1])


def time_min(f, reps):
    f()  # warmup (forces lazy thunks, JIT-irrelevant on CPython but fair)
    best = float("inf")
    for _ in range(reps):
        t0 = time.perf_counter()
        f()
        ms = (time.perf_counter() - t0) * 1000.0
        best = min(best, ms)
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--skip-build", action="store_true")
    args = ap.parse_args()
    if not args.skip_build:
        build()

    native = bench_native()
    node = bench_node()
    purepy = bench_purepy()

    hdr = (f"{'workload':<20} {'purepy':>10} {'node':>10} {'native py':>10} "
           f"{'vs native':>10} {'vs node':>9} {'old purepy':>11}")
    print(hdr)
    print("-" * len(hdr))
    for name in REPS:
        p, n, v = purepy[name], node[name], native[name]
        old_p, _old_v = OLD[name]
        old = f"{old_p / v:.1f}x" if (old_p and v > 0) else "crash"
        print(f"{name:<20} {p:>8.2f}ms {n:>8.2f}ms {v:>8.2f}ms "
              f"{p / v:>9.1f}x {p / n:>8.1f}x {old:>11}")


if __name__ == "__main__":
    main()
