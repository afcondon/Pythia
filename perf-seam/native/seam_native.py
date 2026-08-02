#!/usr/bin/env python3
"""The native arm of the seam-tax lane: the SAME loop, the SAME library calls,
written as a plain Python program with no PureScript anywhere.

Correspondence with `src/Seam/Main.purs` is the whole experiment, so it is
maintained deliberately and narrowly:

  * identical call count (400), identical (a, e) schedule, identical horizons
    and payload sizes;
  * identical solver configuration — DOP853, rtol = atol = 1e-8, both events
    terminal;
  * identical ACCUMULATION ORDER, so the checksums match. Floating-point
    addition is not associative, and the Jurist lane's gate caught two
    separate association bugs in its native arm before this one was written:
    `sum(xs)` (pairwise) and accumulating straight into the running total
    (right association) both diverge from
    `Ref.modify_ (_ + Array.foldl (+) 0.0 xs)` in the last bits. A per-array
    subtotal from 0.0, then one add, is what matches.

The solver body is duplicated from ffi-py/Seam_Kernel_foreign.py rather than
imported. That is intentional: sharing it would make the two arms the same
code path, and there would be nothing left to compare.

    .venv/bin/python native/seam_native.py
"""

import sys
import time

import numpy as np
from scipy.integrate import solve_ivp

R_ESC_SQ = 9.0
TOL = 1.0e-8
MU = 9.54e-4
CALLS = 400
REPS = 3
# Must match ffi-py/Seam_Kernel_foreign.py's workLadder / payloadWork exactly —
# calibrated so this runtime covers the same microsecond range as the others.
HORIZONS = [0.05, 0.12, 0.33, 1.05, 3.0]
PAYLOAD_WORK = 0.33
PAYLOADS = [1, 16, 128, 1024]
SCHEMA = "1"


def cr3bp(t, u, mu):
    x, y, vx, vy = u
    m1 = 1.0 - mu
    dx1 = x + mu
    dx2 = x - 1.0 + mu
    r1sq = dx1 * dx1 + y * y
    r2sq = dx2 * dx2 + y * y
    r1c = r1sq * np.sqrt(r1sq)
    r2c = r2sq * np.sqrt(r2sq)
    return (vx, vy,
            x + 2.0 * vy - m1 * dx1 / r1c - mu * dx2 / r2c,
            y - 2.0 * vx - m1 * y / r1c - mu * y / r2c)


def init_state(mu, a, e):
    rp = a * (1.0 - e)
    x = rp - mu
    return (x, 0.0, 0.0, np.sqrt((1.0 - mu) * (1.0 + e) / rp) - x)


def events(mu):
    r_hill_sq = (mu / 3.0) ** (2.0 / 3.0)

    def escape(t, u, mu_):
        return (u[0] + mu_) ** 2 + u[1] ** 2 - R_ESC_SQ

    def encounter(t, u, mu_):
        return (u[0] - 1.0 + mu_) ** 2 + u[1] ** 2 - r_hill_sq

    escape.terminal = True
    encounter.terminal = True
    return [escape, encounter]


def params_for(i):
    """Mirrors Seam.Main.paramsFor — integer arithmetic, so it costs nothing
    and both arms visit exactly the same orbits."""
    return (0.35 + 0.5 * ((i * 37) % 101) / 100.0,
            0.30 * ((i * 53) % 97) / 96.0)


FOREIGN_NS = [0]


def solve_orbit(mu, a, e, horizon_periods):
    t0 = time.perf_counter_ns()
    horizon = horizon_periods * 2.0 * np.pi
    sol = solve_ivp(cr3bp, (0.0, horizon), init_state(mu, a, e),
                    method="DOP853", args=(mu,), events=events(mu),
                    rtol=TOL, atol=TOL, dense_output=False)
    t_end = sol.t[-1]
    v = 1.0 if t_end >= horizon else round(t_end / horizon, 4)
    FOREIGN_NS[0] += time.perf_counter_ns() - t0
    return v


def solve_orbit_samples(mu, a, e, horizon_periods, n_samples):
    t0 = time.perf_counter_ns()
    horizon = horizon_periods * 2.0 * np.pi
    n = int(n_samples)
    ts = np.linspace(0.0, horizon, n)
    sol = solve_ivp(cr3bp, (0.0, horizon), init_state(mu, a, e),
                    method="DOP853", args=(mu,), events=events(mu),
                    rtol=TOL, atol=TOL, t_eval=ts, dense_output=False)
    xs, ys = sol.y[0], sol.y[1]
    m = len(xs)
    out = [0.0] * (2 * n)
    for i in range(n):
        j = i if i < m else m - 1
        out[2 * i] = float(xs[j])
        out[2 * i + 1] = float(ys[j])
    FOREIGN_NS[0] += time.perf_counter_ns() - t0
    return out


def emit(axis, param, first, r):
    print("SEAM", axis, param, CALLS,
          first / 1000.0, r["total"] / 1000.0, r["inlib"] / 1000.0,
          r["checksum"])
    sys.stdout.flush()


def timed(body):
    """One first pass for the compile/warm-up-dominated number, then REPS more
    keeping the fastest WHOLE pass and its own in-library time. Mirrors `timed`
    in Seam.Main; taking the two from different passes is how a split ends up
    summing to more than the whole."""
    r0 = body()
    best = r0
    for _ in range(REPS):
        r = body()
        if r["total"] < best["total"]:
            best = r
    return r0["total"], best


def run_work(horizon):
    def body():
        FOREIGN_NS[0] = 0
        acc = 0.0
        t0 = time.perf_counter_ns()
        for i in range(CALLS):
            a, e = params_for(i)
            acc += solve_orbit(MU, a, e, horizon)
        t1 = time.perf_counter_ns()
        return {"total": float(t1 - t0), "inlib": float(FOREIGN_NS[0]),
                "checksum": acc}
    first, best = timed(body)
    emit("work", horizon, first, best)


def run_payload(n_samples):
    def body():
        FOREIGN_NS[0] = 0
        acc = 0.0
        t0 = time.perf_counter_ns()
        for i in range(CALLS):
            a, e = params_for(i)
            xs = solve_orbit_samples(MU, a, e, PAYLOAD_WORK, n_samples)
            sub = 0.0
            for v in xs:
                sub += v
            acc += sub
        t1 = time.perf_counter_ns()
        return {"total": float(t1 - t0), "inlib": float(FOREIGN_NS[0]),
                "checksum": acc}
    first, best = timed(body)
    emit("payload", n_samples, first, best)


def main():
    print("SEAM-SCHEMA", SCHEMA)
    sys.stdout.flush()
    for h in HORIZONS:
        run_work(h)
    for n in PAYLOADS:
        run_payload(n)


if __name__ == "__main__":
    main()
