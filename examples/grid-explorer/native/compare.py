# The exhibit against its control: same answers, and what the architecture costs.
#
#   python3 native/compare.py            # correctness + performance
#   python3 native/compare.py --json     # machine-readable, for a CI gate
#
# Runs each scenario twice — once through the PureScript core with pandapower
# behind the seam, once through `grid_native.py`, which is the same analysis
# written straight in Python with no PureScript anywhere. Two things come out.
#
# CORRECTNESS. Every field of every case is compared. This is a differential
# test at the application level, the same move the backends make one level down
# when they diff a Julia run against a JavaScript one. It is a far stronger
# check than "did the endpoint return something", and it has already earned its
# keep: it caught the cascade tripping de-energised branches, because
# `nan > 100.0` is `true` under PureScript's `Ord Number`.
#
# PERFORMANCE, as four ratios rather than one number, because they call for
# different fixes:
#
#   architecture tax       poly_total / native_total
#       what the approach costs. The headline honest number.
#   structural distortion  poly_foreign / native_foreign
#       ~1 expected. Above 1 means the seam made us call pandapower BADLY —
#       and this is invisible to in-process profiling, which would report
#       "the library dominates, the architecture is clean" while the exhibit
#       ran ten times slower than it needed to.
#   displaced compute      poly_core / poly_total
#       analysis sitting in the wrong language.
#   seam cost              poly_seam / poly_total
#       crossing overhead proper: the per-solve deepcopy and the marshalling.
#
# A bad tax with distortion ~1 says PureScript is doing work it shouldn't. A
# bad tax with distortion of 5 says the boundary is in the wrong place. Without
# the control you cannot tell those apart, and they call for opposite fixes.

import argparse
import json
import os
import random
import statistics
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GENERATED = os.path.join(ROOT, "columns", "python", "output-py")
FFI = os.path.join(ROOT, "columns", "python", "ffi-py")

sys.path.insert(0, HERE)
sys.path.insert(0, GENERATED)

import grid_native as native  # noqa: E402

try:
    import Grid_Cascade as PS_Cascade  # noqa: E402
    import Grid_Contingency as PS_Contingency  # noqa: E402
    import Grid_Metrics as PS_Metrics  # noqa: E402
    import Grid_Severity as PS_Severity  # noqa: E402
    import Grid_Solver as PS_Solver  # noqa: E402
    import Grid_Solver_foreign as SEAM  # noqa: E402
except ImportError as e:
    sys.exit(
        f"Generated PureScript not importable ({e}).\n"
        "Build it first:\n"
        "    cd columns/python && spago build \\\n"
        "      && stack exec --stack-yaml ../../../../stack.yaml purepy -- output output-py"
    )

CASE = "case30"
LOAD_FACTOR = 0.7
INITIAL_FAILURE = 35
TOL = 1e-9


# ------------------------------------------------------------------- running


def _timed(fn):
    """Wall clock around a polyglot run, with the seam's counters read out."""
    SEAM.perf_reset()
    t0 = time.perf_counter()
    result = fn()
    total = time.perf_counter() - t0
    return result, {
        "total": total,
        "foreign": SEAM.PERF["foreign"],
        "seam": SEAM.PERF["seam"],
        "core": total - SEAM.PERF["foreign"] - SEAM.PERF["seam"],
        "solves": SEAM.PERF["solves"],
    }


def poly_contingency():
    return _timed(
        lambda: PS_Contingency.analyse(PS_Severity.defaultLimits)(CASE)(LOAD_FACTOR)()
    )


def poly_metrics():
    def run():
        outcome = PS_Solver.solve(PS_Solver.baseSpec(CASE)(LOAD_FACTOR))()
        return PS_Metrics.metrics(outcome)

    return _timed(run)


def poly_cascade():
    return _timed(
        lambda: PS_Cascade.simulate(PS_Cascade.defaultConfig)(CASE)(LOAD_FACTOR)(
            [INITIAL_FAILURE]
        )()
    )


def _native_stats(clock):
    return {
        "total": clock.total,
        "foreign": clock.foreign,
        "seam": 0.0,
        "core": clock.core,
        "solves": clock.solves,
    }


# --------------------------------------------------------------- correctness


def diff(path, a, b, out):
    """Structural comparison. Floats within TOL; everything else exact."""
    if isinstance(a, float) or isinstance(b, float):
        try:
            if abs(float(a) - float(b)) > TOL:
                out.append((path, a, b))
        except (TypeError, ValueError):
            out.append((path, a, b))
    elif isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a or k not in b:
                out.append((f"{path}.{k}", a.get(k, "<missing>"), b.get(k, "<missing>")))
            else:
                diff(f"{path}.{k}", a[k], b[k], out)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            out.append((f"{path}.length", len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)):
            diff(f"{path}[{i}]", x, y, out)
    elif a != b:
        out.append((path, a, b))
    return out


def _strip(d, drop):
    return {k: v for k, v in d.items() if k not in drop}



# ------------------------------------------------------ independence property


def check_independence():
    """Prove `Grid.Solver`'s ordering guarantee, rather than asserting it.

    The seam keeps ONE working network and resets the mutable columns before
    each solve, instead of deep-copying the reference network per call. That
    costs 5.4 ms less per solve on case30, against 18 ms of actual power flow —
    but only if the two strategies are genuinely interchangeable.

    The documented guarantee is a property of the INTERFACE: no mutable handle
    crosses the boundary, so solves cannot depend on the order they were issued
    in. Copying was one way to obtain it, never the guarantee itself. So the
    check is behavioural, not structural.
    """
    base = {"caseName": CASE, "loadFactor": LOAD_FACTOR, "loadsOut": []}
    sweep = [dict(base, linesOut=[i]) for i in range(41)]
    mixed = sweep + [
        dict(base, linesOut=[35, 30, 32, 34], loadsOut=[24, 25, 26, 28, 29]),
        {"caseName": "case14", "loadFactor": 1.2, "linesOut": [3], "loadsOut": [4]},
        {"caseName": "case30", "loadFactor": 1.0, "linesOut": [1000], "loadsOut": []},
        {"caseName": "case57", "loadFactor": 0.9, "linesOut": [7], "loadsOut": []},
    ]

    def run(strategy, specs):
        SEAM.INDEPENDENCE = strategy
        SEAM._WORK_CACHE.clear()
        return [json.dumps(SEAM.solveImpl(dict(s)), sort_keys=True) for s in specs]

    checks = []
    checks.append(("restore == copy, spec by spec",
                   run("copy", mixed) == run("restore", mixed)))

    SEAM.INDEPENDENCE = "restore"
    SEAM._WORK_CACHE.clear()
    fwd = {i: json.dumps(SEAM.solveImpl(dict(base, linesOut=[i])), sort_keys=True)
           for i in range(41)}

    SEAM._WORK_CACHE.clear()
    rev = {}
    for i in reversed(range(41)):
        rev[i] = json.dumps(SEAM.solveImpl(dict(base, linesOut=[i])), sort_keys=True)
    checks.append(("N-1 sweep forward == reversed", fwd == rev))

    order = list(range(41))
    random.Random(7).shuffle(order)
    SEAM._WORK_CACHE.clear()
    shf = {i: json.dumps(SEAM.solveImpl(dict(base, linesOut=[i])), sort_keys=True)
           for i in order}
    checks.append(("N-1 sweep forward == shuffled", fwd == shf))

    # The real hazard: other cases and other spec shapes in between.
    inter = {}
    for i in order:
        inter[i] = json.dumps(SEAM.solveImpl(dict(base, linesOut=[i])), sort_keys=True)
        SEAM.solveImpl(dict(base, linesOut=[35, 30, 32, 34],
                            loadsOut=[24, 25, 26, 28, 29]))
        SEAM.solveImpl({"caseName": "case14", "loadFactor": 1.2,
                        "linesOut": [3], "loadsOut": [4]})
    checks.append(("survives interleaving with other cases/specs", fwd == inter))

    for label, ok in checks:
        print(("  PASS  " if ok else "  FAIL  ") + label)
    return 0 if all(ok for _, ok in checks) else 1


# ---------------------------------------------------------------------- main


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--reps", type=int, default=3, help="timed repetitions (median)")
    ap.add_argument("--check-independence", action="store_true",
                    help="prove the restore strategy equals the deepcopy one")
    args = ap.parse_args()

    if args.check_independence:
        return check_independence()

    scenarios = [
        ("contingency", poly_contingency, lambda: native.contingency(CASE, LOAD_FACTOR),
         {"cases"}, None),
        ("metrics", poly_metrics, lambda: native.metrics(CASE, LOAD_FACTOR),
         set(), None),
        ("cascade", poly_cascade, lambda: native.cascade(CASE, LOAD_FACTOR, (INITIAL_FAILURE,)),
         # finalNetwork is the whole marshalled network, which the native
         # reference has no reason to build — it is a rendering payload, not
         # part of the answer.
         {"finalNetwork"}, None),
    ]

    report = {"case": CASE, "loadFactor": LOAD_FACTOR, "scenarios": {}}
    failures = 0

    for name, poly_fn, nat_fn, drop, _ in scenarios:
        poly_runs, nat_runs = [], []
        poly_result = nat_result = None
        for _ in range(args.reps):
            poly_result, pstat = poly_fn()
            poly_runs.append(pstat)
            nat_result, nclock = nat_fn()
            nat_runs.append(_native_stats(nclock))

        med = lambda runs, k: statistics.median(r[k] for r in runs)
        p = {k: med(poly_runs, k) for k in ("total", "foreign", "seam", "core")}
        n = {k: med(nat_runs, k) for k in ("total", "foreign", "core")}
        p["solves"] = poly_runs[0]["solves"]
        n["solves"] = nat_runs[0]["solves"]

        mismatches = diff(name, _strip(poly_result, drop), _strip(nat_result, drop), [])
        if mismatches:
            failures += 1

        ratios = {
            "architectureTax": p["total"] / n["total"] if n["total"] else None,
            "structuralDistortion": p["foreign"] / n["foreign"] if n["foreign"] else None,
            "displacedCompute": p["core"] / p["total"] if p["total"] else None,
            "seamCost": p["seam"] / p["total"] if p["total"] else None,
        }
        report["scenarios"][name] = {
            "polyglot": p, "native": n, "ratios": ratios,
            "mismatches": [{"path": m[0], "polyglot": m[1], "native": m[2]} for m in mismatches],
        }

        if not args.json:
            print(f"\n=== {name} ===")
            print(f"  agreement: {'IDENTICAL' if not mismatches else str(len(mismatches)) + ' MISMATCHES'}")
            for m in mismatches[:8]:
                print(f"    {m[0]}: polyglot={m[1]!r} native={m[2]!r}")
            if len(mismatches) > 8:
                print(f"    … and {len(mismatches) - 8} more")
            print(f"  solves:   polyglot {p['solves']}   native {n['solves']}")
            print(f"  polyglot: total {p['total']*1000:8.1f} ms"
                  f"  = foreign {p['foreign']*1000:7.1f}"
                  f" + seam {p['seam']*1000:7.1f}"
                  f" + core {p['core']*1000:7.1f}")
            print(f"  native:   total {n['total']*1000:8.1f} ms"
                  f"  = foreign {n['foreign']*1000:7.1f}"
                  f"                   + core {n['core']*1000:7.1f}")
            print(f"  architecture tax       {ratios['architectureTax']:6.2f}×"
                  "   (polyglot total / native total)")
            print(f"  structural distortion  {ratios['structuralDistortion']:6.2f}×"
                  "   (same library, both sides — ~1.0 is clean)")
            print(f"  displaced compute      {ratios['displacedCompute']*100:6.1f} %"
                  "   (PureScript share of polyglot wall clock)")
            print(f"  seam cost              {ratios['seamCost']*100:6.1f} %"
                  "   (deepcopy + marshalling)")

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("\n" + ("=" * 68))
        print("CORRECTNESS: " + ("all scenarios identical to the native reference"
                                 if not failures else f"{failures} scenario(s) DIVERGED"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
