#!/usr/bin/env python3
"""
Benchmark harness for PureScript-Python generated code.

Compares:
1. PureScript compiled to Python
2. Hand-written Python equivalents
3. Optionally: PyPy performance
"""

import sys
import time

sys.path.insert(0, '../output-py')

def timeit(name, f, iterations=1):
    """Time a function and print results."""
    start = time.perf_counter()
    for _ in range(iterations):
        result = f()
    elapsed = time.perf_counter() - start
    avg = elapsed / iterations * 1000  # ms
    print(f"  {name}: {avg:.2f}ms (result: {result})")
    return avg

def fib_python(n):
    """Hand-written Python fibonacci."""
    if n <= 1:
        return n
    return fib_python(n - 1) + fib_python(n - 2)

def apply_n_python(f, n, x):
    """Apply f to x, n times."""
    for _ in range(n):
        x = f(x)
    return x

class Leaf:
    def __init__(self, value):
        self.value = value

class Branch:
    def __init__(self, left, right):
        self.left = left
        self.right = right

def build_tree_python(n):
    if n == 0:
        return Leaf(1)
    return Branch(build_tree_python(n - 1), build_tree_python(n - 1))

def sum_tree_python(tree):
    if isinstance(tree, Leaf):
        return tree.value
    return sum_tree_python(tree.left) + sum_tree_python(tree.right)

def sum_to_python(acc, n):
    """Sum from 1 to n."""
    while n > 0:
        acc += n
        n -= 1
    return acc

def run_python_benchmarks():
    """Run hand-written Python benchmarks."""
    print("\n=== Hand-written Python ===")
    timeit("fib(30)", lambda: fib_python(30))
    timeit("tree sum (depth 15)", lambda: sum_tree_python(build_tree_python(15)))
    timeit("apply inc 100x", lambda: apply_n_python(lambda x: x + 1, 100, 0))
    timeit("sumTo 100", lambda: sum_to_python(0, 100))

def run_purescript_benchmarks():
    """Run PureScript-generated Python benchmarks."""
    print("\n=== PureScript-Python ===")

    try:
        import bench
    except ImportError as e:
        print(f"  Error importing bench module: {e}")
        print("  Run: spago build && purepy output output-py")
        return

    # Individual benchmarks
    timeit("fib(30)", lambda: bench.fib(30))
    timeit("tree sum (depth 15)", lambda: bench.sumTree(bench.buildTree(15)))
    timeit("apply inc 100x", lambda: bench.applyN(bench.inc)(100)(0))
    timeit("sumTo 100", lambda: bench.sumTo(0)(100))

def run_purescript_precomputed():
    """Access pre-computed benchmark results."""
    print("\n=== PureScript Pre-computed (computed at import time) ===")

    try:
        import bench
        results = bench.benchmarks
        print(f"  fib30: {results['fib30']}")
        print(f"  treeSum: {results['treeSum']}")
        print(f"  applyInc: {results['applyInc']}")
        print(f"  sumTo100: {results['sumTo100']}")
    except Exception as e:
        print(f"  Error: {e}")

def main():
    print("=" * 60)
    print("PureScript-Python Benchmark Suite")
    print("=" * 60)

    run_python_benchmarks()
    run_purescript_benchmarks()
    run_purescript_precomputed()

    print("\n" + "=" * 60)
    print("Notes:")
    print("- Lower times are better")
    print("- PureScript has currying and thunk overhead")
    print("- Run with PyPy for comparison: pypy3 run_benchmarks.py")
    print("=" * 60)

if __name__ == "__main__":
    main()
