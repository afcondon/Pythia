# The seam: pandapower, and nothing else.
#
# One operation — solve a named IEEE reference case at a load factor with a
# given set of branches and loads out of service — plus the marshalling needed
# to hand the result back as plain records.
#
# Deliberately contains no analysis. Which branches to open, what counts as a
# violation, how a cascade propagates and what the topology metrics are all
# live in PureScript (Grid.Contingency, Grid.Severity, Grid.Cascade,
# Grid.Graph, Grid.Metrics). If logic starts accumulating here, that is the
# regression this exhibit was rebuilt to remove.

import copy
import time

import numpy as np
import pandapower as pp
import pandapower.networks as pn

# Attribution counters, read by native/compare.py.
#
# `foreign` is time inside pandapower — the SAME library call the native
# reference makes, so `poly_foreign / native_foreign` is measurable. That ratio
# is the one number no amount of in-process profiling can produce, and the one
# that says whether the seam deformed the computation rather than merely
# costing something to cross.
#
# `seam` is what crossing costs: the per-call deepcopy of the network and the
# marshalling of the result into plain records. Everything else in the wall
# clock is PureScript.
PERF = {"foreign": 0.0, "seam": 0.0, "copy": 0.0, "marshal": 0.0, "solves": 0}


def perf_reset():
    PERF.update(foreign=0.0, seam=0.0, copy=0.0, marshal=0.0, solves=0)

# Reference networks. case30 is the demo default: unlike case14 it ships real
# per-line thermal ratings (six distinct values rather than one placeholder),
# which is what lets a contingency actually exceed a limit.
_CASES = {
    "case14": pn.case14,
    "case30": pn.case30,
    "case57": pn.case57,
    "case118": pn.case118,
    "case_ieee30": pn.case_ieee30,
}

_BASE_CACHE = {}


def _base_net(case_name):
    if case_name not in _CASES:
        raise ValueError(f"Unknown case: {case_name}. Available: {sorted(_CASES)}")
    if case_name not in _BASE_CACHE:
        net = _CASES[case_name]()
        net.name = case_name
        _BASE_CACHE[case_name] = net
    return copy.deepcopy(_BASE_CACHE[case_name])


# Which columns a `SolveSpec` is allowed to touch. Everything else about the
# network is immutable, and the result tables are outputs — overwritten by the
# next solve, so they need no restoring.
_MUTABLE = (
    ("line", "in_service"),
    ("trafo", "in_service"),
    ("load", "in_service"),
    ("load", "p_mw"),
    ("load", "q_mvar"),
    ("gen", "in_service"),
    ("ext_grid", "in_service"),
)

_WORK_CACHE = {}

# "copy" deep-copies the reference network per solve; "restore" keeps one
# working network and resets the mutable columns before each. Both give the
# SAME GUARANTEE — the one `Grid.Solver` actually documents, that no mutable
# handle crosses the boundary and solves cannot depend on their order. That is
# a property of the interface, not of the implementation, and copying was only
# ever one way to get it. Copying costs ~5.4 ms per solve on case30, against
# 18 ms of actual power flow.
#
# `native/compare.py --check-independence` proves they agree: it diffs the two
# strategies over a spec set and runs the N-1 sweep forward, reversed and
# shuffled, asserting identical results. A guarantee that is only asserted in a
# comment is not a guarantee.
INDEPENDENCE = "restore"


def _work_net(case_name):
    """A network with the mutable columns reset to their reference values."""
    if INDEPENDENCE == "copy":
        return _base_net(case_name)

    if case_name not in _WORK_CACHE:
        net = _base_net(case_name)
        baseline = {
            (f, c): getattr(net, f)[c].values.copy()
            for f, c in _MUTABLE
            if c in getattr(net, f).columns
        }
        _WORK_CACHE[case_name] = (net, baseline)

    net, baseline = _WORK_CACHE[case_name]
    for (f, c), values in baseline.items():
        getattr(net, f)[c] = values.copy()
    return net


def _layout(net):
    """Circular layout, purely for drawing — the frontend wants coordinates."""
    n = len(net.bus)
    return {
        idx: (
            float(np.cos(2 * np.pi * i / n) * (100 + (i % 3) * 20)),
            float(np.sin(2 * np.pi * i / n) * (100 + (i % 3) * 20)),
        )
        for i, idx in enumerate(net.bus.index)
    }


def _rating_mva(net, row):
    """Thermal rating in MVA, from the line's current rating and its voltage."""
    if row.max_i_ka and row.max_i_ka > 0:
        return float(row.max_i_ka * net.bus.at[row.from_bus, "vn_kv"] * np.sqrt(3))
    return 0.0


_STATIC_CACHE = {}


def _static(case_name):
    """Everything about a case that no solve can change.

    Identity, topology, geometry and thermal ratings are properties of the
    network, not of a power flow over it. Recomputing them 42 times — once per
    N-1 outage — is pure waste, and it was most of what the seam cost.

    Measured on case30 before this existed: the per-bus load lookup alone was
    3.15 ms of a 7.41 ms marshal, because it ran a pandas boolean mask per bus;
    `_rating_mva` another 0.98 ms, doing a scalar `.at` lookup per line for a
    number that never changes; `.iterrows()` a further 0.85 ms. Roughly 60 % of
    "seam cost" was naive pandas rather than anything to do with having a seam.
    """
    if case_name in _STATIC_CACHE:
        return _STATIC_CACHE[case_name]

    net = _base_net(case_name)
    pos = _layout(net)
    slack = set(net.ext_grid.bus.values)
    pv = set(net.gen.bus.values)

    bus_ids = [int(i) for i in net.bus.index]
    bus_static = []
    for idx in net.bus.index:
        x, y = pos.get(idx, (0.0, 0.0))
        name = net.bus.at[idx, "name"] if "name" in net.bus.columns else None
        bus_static.append({
            "id": int(idx),
            "name": str(name) if name else f"Bus {idx}",
            "busType": "slack" if idx in slack else ("pv" if idx in pv else "pq"),
            "hasGenerator": bool(idx in pv or idx in slack),
            "x": x,
            "y": y,
        })

    line_static = [
        {
            "id": int(idx),
            "fromBus": int(row.from_bus),
            "toBus": int(row.to_bus),
            "maxLoadingMva": _num(_rating_mva(net, row)),
            "isTransformer": False,
        }
        for idx, row in net.line.iterrows()
    ]
    trafo_static = [
        {
            "id": int(1000 + idx),
            "fromBus": int(row.hv_bus),
            "toBus": int(row.lv_bus),
            "maxLoadingMva": _num(row.sn_mva) if row.sn_mva and row.sn_mva > 0 else 0.0,
            "isTransformer": True,
        }
        for idx, row in net.trafo.iterrows()
    ]

    static = {
        "busIds": bus_ids,
        "buses": bus_static,
        "lines": line_static,
        "trafos": trafo_static,
        "genBuses": [int(r.bus) for _, r in net.gen.iterrows()],
        "extBuses": [int(r.bus) for _, r in net.ext_grid.iterrows()],
        "baseMva": _num(net.sn_mva, 100.0) if hasattr(net, "sn_mva") else 100.0,
    }
    _STATIC_CACHE[case_name] = static
    return static


def _loads_by_bus(net):
    """In-service load at every bus, in one grouped pass.

    Was a pandas boolean mask per bus inside the marshalling loop — O(buses)
    dataframe scans per solve, for a quantity one `groupby` answers.
    """
    live = net.load[net.load.in_service]
    if len(live) == 0:
        return {}, {}
    grouped = live.groupby(live.bus.astype(int))[["p_mw", "q_mvar"]].sum()
    return grouped.p_mw.to_dict(), grouped.q_mvar.to_dict()


def _num(x, fallback=0.0):
    """A finite float, or the fallback.

    **The seam's contract: no NaN crosses this boundary.** pandapower reports
    NaN for elements it could not solve — a bus with no path to a source has no
    voltage, and a branch inside that island has no flow. Those NaNs used to
    travel into PureScript, where they are not merely useless but actively
    wrong: `Ord Number` is `unsafeCompare`, which tries `<`, then `==`, and
    otherwise answers `GT`, so `nan > 100.0` is `true` on every backend
    including the JavaScript reference. Every de-energised branch read as
    "over its thermal rating", and the cascade tripped it. A three-branch
    outage was reported as seven.

    Faithfulness is preserved by the companion `energised` flag rather than by
    the number: callers are told the value is not a result, instead of having
    to detect it from the value itself.

    It also produced invalid JSON. `json.dumps` emits a bare `NaN` token, which
    no conforming parser accepts — `JSON.parse` in the browser throws on it.
    """
    try:
        f = float(x)
    except (TypeError, ValueError):
        return fallback
    return f if np.isfinite(f) else fallback


def _col(frame, name, n):
    """A result column as a plain numpy array, or NaNs if the solve has none."""
    if frame is not None and len(frame) == n and name in frame.columns:
        return frame[name].values
    return np.full(n, np.nan)


def _marshal(net, converged):
    """Solve results into plain records, joined onto the cached static data.

    Reads each result column once as a numpy array and indexes positionally,
    rather than walking `.iterrows()` and doing scalar `.at` lookups per field.
    Same output, and the byte-equality of that is asserted in `native/compare.py`
    against the pre-vectorisation implementation.
    """
    st = _static(str(net.name))
    has = converged and hasattr(net, "res_bus") and len(net.res_bus) > 0

    n_bus = len(net.bus)
    vm = _col(net.res_bus if has else None, "vm_pu", n_bus)
    va = _col(net.res_bus if has else None, "va_degree", n_bus)
    p_mw_by_bus, q_mvar_by_bus = _loads_by_bus(net)

    buses = []
    for i, s in enumerate(st["buses"]):
        energised = bool(has and np.isfinite(vm[i]))
        bid = s["id"]
        buses.append({
            **s,
            "voltagePu": _num(vm[i], 1.0) if energised else 1.0,
            "angleRad": _num(np.radians(va[i])) if energised else 0.0,
            "loadMw": _num(p_mw_by_bus.get(bid, 0.0)),
            "loadMvar": _num(q_mvar_by_bus.get(bid, 0.0)),
            "energised": energised,
        })

    lines = []
    for frame_name, res_name, static_key, p_col, q_col in (
        ("line", "res_line", "lines", "p_from_mw", "q_from_mvar"),
        # Transformers travel as branches too — the frontend draws them the
        # same way — with ids offset so they stay distinguishable.
        ("trafo", "res_trafo", "trafos", "p_hv_mw", "q_hv_mvar"),
    ):
        frame = getattr(net, frame_name)
        n = len(frame)
        res = getattr(net, res_name, None) if has else None
        in_service = frame.in_service.values
        loading = _col(res, "loading_percent", n)
        p = _col(res, p_col, n)
        q = _col(res, q_col, n)
        for i, s in enumerate(st[static_key]):
            live = bool(in_service[i])
            energised = bool(has and live and np.isfinite(loading[i]))
            lines.append({
                **s,
                "loadingPercent": _num(loading[i]) if energised else 0.0,
                "inService": live,
                "energised": energised,
                "pFromMw": _num(p[i]) if energised else 0.0,
                "qFromMvar": _num(q[i]) if energised else 0.0,
            })

    generators = []
    for frame_name, res_name, offset, max_col in (
        ("gen", "res_gen", 0, "max_p_mw"),
        ("ext_grid", "res_ext_grid", 1000, None),
    ):
        frame = getattr(net, frame_name)
        n = len(frame)
        res = getattr(net, res_name, None) if has else None
        live_res = has and res is not None and len(res) == n
        p = _col(res, "p_mw", n)
        q = _col(res, "q_mvar", n)
        buses_of = frame.bus.values
        in_service = frame.in_service.values
        max_p = frame[max_col].values if max_col and max_col in frame.columns else None
        for i, idx in enumerate(frame.index):
            generators.append({
                "id": int(offset + idx),
                "bus": int(buses_of[i]),
                "pMw": _num(p[i]) if live_res else 0.0,
                "qMvar": _num(q[i]) if live_res else 0.0,
                "inService": bool(in_service[i]),
                "pMaxMw": _num(max_p[i]) if max_p is not None else 0.0,
            })

    # nansum, not sum: an islanded branch contributes no loss, and one NaN in
    # a plain sum would make the whole network total NaN.
    total_load = _num(np.nansum(net.res_load.p_mw.values)) if has else 0.0
    total_gen = _num(
        np.nansum(net.res_gen.p_mw.values) + np.nansum(net.res_ext_grid.p_mw.values)
    ) if has else 0.0
    total_loss = _num(
        np.nansum(net.res_line.pl_mw.values) + np.nansum(net.res_trafo.pl_mw.values)
    ) if has else 0.0

    return {
        "converged": bool(converged),
        "name": str(net.name) if getattr(net, "name", None) else "network",
        "baseMva": _num(net.sn_mva, 100.0) if hasattr(net, "sn_mva") else 100.0,
        "buses": buses,
        "lines": lines,
        "generators": generators,
        "totalLoadMw": total_load,
        "totalGenMw": total_gen,
        "totalLossMw": total_loss,
    }


def solveImpl(spec):
    """EffectFn1 SolveSpec SolveOutcome — called saturated, so a plain def."""
    _t_seam = time.perf_counter()
    net = _work_net(spec["caseName"])

    # Load scaling. This is what `loadFactor` was always documented to do and
    # never did: before this, the parameter was accepted and dropped, so every
    # load factor produced byte-identical output.
    lf = float(spec.get("loadFactor", 1.0))
    if lf != 1.0:
        net.load.p_mw = net.load.p_mw * lf
        net.load.q_mvar = net.load.q_mvar * lf

    for lid in spec.get("linesOut", []):
        lid = int(lid)
        if lid >= 1000:
            t = lid - 1000
            if t in net.trafo.index:
                net.trafo.at[t, "in_service"] = False
        elif lid in net.line.index:
            net.line.at[lid, "in_service"] = False

    loads_out = spec.get("loadsOut", [])
    if len(loads_out):
        # One vectorised mask, not a scalar `.at` write per (load, bus) pair.
        net.load.loc[net.load.bus.astype(int).isin([int(b) for b in loads_out]),
                     "in_service"] = False

    _d = time.perf_counter() - _t_seam
    PERF["seam"] += _d
    PERF["copy"] += _d

    _t = time.perf_counter()
    try:
        pp.runpp(net)
        converged = True
    except Exception:
        converged = False
    PERF["foreign"] += time.perf_counter() - _t
    PERF["solves"] += 1

    _t_seam = time.perf_counter()
    out = _marshal(net, converged)
    _d = time.perf_counter() - _t_seam
    PERF["seam"] += _d
    PERF["marshal"] += _d
    return out
