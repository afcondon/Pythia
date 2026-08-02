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


def _marshal(net, converged):
    pos = _layout(net)
    slack = set(net.ext_grid.bus.values)
    pv = set(net.gen.bus.values)
    has = converged and hasattr(net, "res_bus") and len(net.res_bus) > 0

    buses = []
    for idx, row in net.bus.iterrows():
        loads = net.load[(net.load.bus == idx) & net.load.in_service]
        x, y = pos.get(idx, (0.0, 0.0))
        # Energised: the solve produced a real voltage for this bus. An
        # islanded bus is not "at 0 pu" (that would read as a catastrophic
        # undervoltage) — it has no voltage, and the flag is how we say so.
        vm = net.res_bus.at[idx, "vm_pu"] if has else None
        energised = has and vm is not None and np.isfinite(vm)
        buses.append({
            "id": int(idx),
            "name": str(row.get("name", "") or f"Bus {idx}"),
            "busType": "slack" if idx in slack else ("pv" if idx in pv else "pq"),
            "voltagePu": _num(vm, 1.0) if energised else 1.0,
            "angleRad": _num(np.radians(net.res_bus.at[idx, "va_degree"])) if energised else 0.0,
            "loadMw": _num(loads.p_mw.sum()) if len(loads) else 0.0,
            "loadMvar": _num(loads.q_mvar.sum()) if len(loads) else 0.0,
            "hasGenerator": bool(idx in pv or idx in slack),
            "energised": bool(energised),
            "x": x,
            "y": y,
        })

    lines = []
    for idx, row in net.line.iterrows():
        live = has and idx in net.res_line.index and bool(row.in_service)
        loading = net.res_line.at[idx, "loading_percent"] if live else None
        energised = live and np.isfinite(loading)
        lines.append({
            "id": int(idx),
            "fromBus": int(row.from_bus),
            "toBus": int(row.to_bus),
            "loadingPercent": _num(loading) if energised else 0.0,
            "maxLoadingMva": _num(_rating_mva(net, row)),
            "inService": bool(row.in_service),
            "energised": bool(energised),
            "pFromMw": _num(net.res_line.at[idx, "p_from_mw"]) if energised else 0.0,
            "qFromMvar": _num(net.res_line.at[idx, "q_from_mvar"]) if energised else 0.0,
            "isTransformer": False,
        })

    # Transformers travel as branches too — the frontend draws them the same
    # way — with ids offset so they stay distinguishable.
    for idx, row in net.trafo.iterrows():
        live = has and idx in net.res_trafo.index and bool(row.in_service)
        loading = net.res_trafo.at[idx, "loading_percent"] if live else None
        energised = live and np.isfinite(loading)
        lines.append({
            "id": int(1000 + idx),
            "fromBus": int(row.hv_bus),
            "toBus": int(row.lv_bus),
            "loadingPercent": _num(loading) if energised else 0.0,
            "maxLoadingMva": _num(row.sn_mva) if row.sn_mva and row.sn_mva > 0 else 0.0,
            "inService": bool(row.in_service),
            "energised": bool(energised),
            "pFromMw": _num(net.res_trafo.at[idx, "p_hv_mw"]) if energised else 0.0,
            "qFromMvar": _num(net.res_trafo.at[idx, "q_hv_mvar"]) if energised else 0.0,
            "isTransformer": True,
        })

    generators = []
    for idx, row in net.gen.iterrows():
        live = has and idx in net.res_gen.index
        generators.append({
            "id": int(idx),
            "bus": int(row.bus),
            "pMw": _num(net.res_gen.at[idx, "p_mw"]) if live else 0.0,
            "qMvar": _num(net.res_gen.at[idx, "q_mvar"]) if live else 0.0,
            "inService": bool(row.in_service),
            "pMaxMw": _num(row.max_p_mw) if "max_p_mw" in row else 0.0,
        })
    for idx, row in net.ext_grid.iterrows():
        live = has and idx in net.res_ext_grid.index
        generators.append({
            "id": int(1000 + idx),
            "bus": int(row.bus),
            "pMw": _num(net.res_ext_grid.at[idx, "p_mw"]) if live else 0.0,
            "qMvar": _num(net.res_ext_grid.at[idx, "q_mvar"]) if live else 0.0,
            "inService": bool(row.in_service),
            "pMaxMw": 0.0,
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
    net = _base_net(spec["caseName"])

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

    for bus_id in spec.get("loadsOut", []):
        for idx in net.load.index:
            if int(net.load.at[idx, "bus"]) == int(bus_id):
                net.load.at[idx, "in_service"] = False

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
