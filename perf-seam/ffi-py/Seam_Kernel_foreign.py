# The foreign side of the seam-tax lane, Pythia edition.
#
# Rule for this file: it contains a LIBRARY CALL and the marshalling around
# it, and nothing else. No loop, no grid, no algorithm — those live in
# PureScript, which is the whole point of the measurement. If the sweep loop
# migrated in here the numbers would flatter us and would be measuring a
# different architecture.
#
# The physics is identical to purescript-julia/perf-seam so the two runtimes
# land on one scale: the same CR3BP, the same escape and Hill-sphere events
# located by root-finding, the same tolerance. The solver differs because the
# ecosystems differ — DOP853 is scipy's high-order adaptive Runge-Kutta, the
# nearest thing it has to Vern9 — and that is the honest comparison, since the
# point is reaching each runtime's OWN library.
#
# purepy calling convention: curried PureScript arrives as nested unary
# lambdas, and an `Effect` is a zero-argument callable.

import time as _time

import numpy as _np
from scipy.integrate import solve_ivp as _solve_ivp

_R_ESC_SQ = 9.0
_TOL = 1.0e-8

# --- the vector field (identical to the native arm) --------------------------


def _cr3bp(t, u, mu):
    x, y, vx, vy = u
    m1 = 1.0 - mu
    dx1 = x + mu
    dx2 = x - 1.0 + mu
    r1sq = dx1 * dx1 + y * y
    r2sq = dx2 * dx2 + y * y
    r1c = r1sq * _np.sqrt(r1sq)
    r2c = r2sq * _np.sqrt(r2sq)
    return (vx, vy,
            x + 2.0 * vy - m1 * dx1 / r1c - mu * dx2 / r2c,
            y - 2.0 * vx - m1 * y / r1c - mu * y / r2c)


def _init(mu, a, e):
    rp = a * (1.0 - e)
    x = rp - mu
    return (x, 0.0, 0.0, _np.sqrt((1.0 - mu) * (1.0 + e) / rp) - x)


def _events(mu):
    r_hill_sq = (mu / 3.0) ** (2.0 / 3.0)

    def escape(t, u, mu_):
        return (u[0] + mu_) ** 2 + u[1] ** 2 - _R_ESC_SQ

    def encounter(t, u, mu_):
        return (u[0] - 1.0 + mu_) ** 2 + u[1] ** 2 - r_hill_sq

    escape.terminal = True
    encounter.terminal = True
    return [escape, encounter]


# --- instrumentation ---------------------------------------------------------

# Nanoseconds spent INSIDE scipy, summed by the foreign itself. A one-element
# list rather than a module global so the closures below can mutate it without
# a `global` statement on every call.
_FOREIGN_NS = [0]

foreignNs = lambda: float(_FOREIGN_NS[0])


def resetForeignNs():
    _FOREIGN_NS[0] = 0
    return None


# --- the clock ---------------------------------------------------------------

nowNs = lambda: float(_time.perf_counter_ns())


def flushOut():
    import sys
    sys.stdout.flush()
    return None


# --- the seam ----------------------------------------------------------------


def _verdict(sol, horizon):
    t_end = sol.t[-1]
    return 1.0 if t_end >= horizon else round(t_end / horizon, 4)


# callLibrary :: Number -> Number -> Number -> Number -> Number
# The shared PureScript names these three shape dials and a work dial; here
# they are (mu, a, e, horizon_periods) because this backend binds an ODE
# solver.
def callLibrary(mu):
    def _a(a):
        def _e(e):
            def _h(horizon_periods):
                t0 = _time.perf_counter_ns()
                horizon = horizon_periods * 2.0 * _np.pi
                sol = _solve_ivp(
                    _cr3bp, (0.0, horizon), _init(mu, a, e),
                    method="DOP853", args=(mu,),
                    events=_events(mu), rtol=_TOL, atol=_TOL,
                    dense_output=False)
                v = _verdict(sol, horizon)
                _FOREIGN_NS[0] += _time.perf_counter_ns() - t0
                return v
            return _h
        return _e
    return _a


# callLibraryPayload :: Number -> Number -> Number -> Number -> Int -> Array Number
def callLibraryPayload(mu):
    def _a(a):
        def _e(e):
            def _h(horizon_periods):
                def _n(n_samples):
                    t0 = _time.perf_counter_ns()
                    horizon = horizon_periods * 2.0 * _np.pi
                    n = int(n_samples)
                    ts = _np.linspace(0.0, horizon, n)
                    sol = _solve_ivp(
                        _cr3bp, (0.0, horizon), _init(mu, a, e),
                        method="DOP853", args=(mu,),
                        events=_events(mu), rtol=_TOL, atol=_TOL,
                        t_eval=ts, dense_output=False)
                    # Flat [x0,y0,x1,y1,...] — the shape every backend marshals
                    # the same way, so the payload number is comparable across
                    # runtimes. A list, not an ndarray: `Array Number` on the
                    # PureScript side is a list here, and handing back an
                    # ndarray would measure numpy's iteration rather than the
                    # crossing.
                    xs = sol.y[0]
                    ys = sol.y[1]
                    m = len(xs)
                    out = [0.0] * (2 * n)
                    for i in range(n):
                        j = i if i < m else m - 1
                        out[2 * i] = float(xs[j])
                        out[2 * i + 1] = float(ys[j])
                    _FOREIGN_NS[0] += _time.perf_counter_ns() - t0
                    return out
                return _n
            return _h
        return _e
    return _a


# --- the calibrated ladders --------------------------------------------------
#
# The axis under test is MICROSECONDS of library work bought per crossing; the
# horizon is only the dial that moves it. Each backend calibrates its own
# ladder to span the SAME microsecond range, which is what makes the runtimes
# comparable and what lets the shared PureScript stay byte-identical (see
# Seam.Kernel.workLadder).
#
# Calibration matters here more than it looks. Measured 2026-08-02, one
# 150-period solve costs ~10 ms through OrdinaryDiffEq and ~497 ms through
# scipy — a factor of FIFTY, because scipy's DOP853 evaluates the right-hand
# side through a Python callback while Julia specialises it to native code.
# Reusing Julia's ladder here would have taken about fifty minutes and would
# have measured a range no part of which overlapped Julia's.
#
# scipy costs ~3350 us per Jupiter period on this machine, so these settings
# buy roughly 170 / 400 / 1100 / 3500 / 10000 us per call — matching the Julia
# ladder to within a few percent.
workLadder = [0.05, 0.12, 0.33, 1.05, 3.0]

# ~1100 us per call: the middle of the ladder, so the payload axis varies
# payload against a representative amount of work rather than an extreme.
payloadWork = 0.33
