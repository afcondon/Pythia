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

import numpy as np
import pandapower as pp
import pandapower.networks as pn

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


def _marshal(net, converged):
    pos = _layout(net)
    slack = set(net.ext_grid.bus.values)
    pv = set(net.gen.bus.values)
    has = converged and hasattr(net, "res_bus") and len(net.res_bus) > 0

    buses = []
    for idx, row in net.bus.iterrows():
        loads = net.load[(net.load.bus == idx) & net.load.in_service]
        x, y = pos.get(idx, (0.0, 0.0))
        buses.append({
            "id": int(idx),
            "name": str(row.get("name", "") or f"Bus {idx}"),
            "busType": "slack" if idx in slack else ("pv" if idx in pv else "pq"),
            "voltagePu": float(net.res_bus.at[idx, "vm_pu"]) if has else 1.0,
            "angleRad": float(np.radians(net.res_bus.at[idx, "va_degree"])) if has else 0.0,
            "loadMw": float(loads.p_mw.sum()) if len(loads) else 0.0,
            "loadMvar": float(loads.q_mvar.sum()) if len(loads) else 0.0,
            "hasGenerator": bool(idx in pv or idx in slack),
            "x": x,
            "y": y,
        })

    lines = []
    for idx, row in net.line.iterrows():
        live = has and idx in net.res_line.index and bool(row.in_service)
        lines.append({
            "id": int(idx),
            "fromBus": int(row.from_bus),
            "toBus": int(row.to_bus),
            "loadingPercent": float(net.res_line.at[idx, "loading_percent"]) if live else 0.0,
            "maxLoadingMva": _rating_mva(net, row),
            "inService": bool(row.in_service),
            "pFromMw": float(net.res_line.at[idx, "p_from_mw"]) if live else 0.0,
            "qFromMvar": float(net.res_line.at[idx, "q_from_mvar"]) if live else 0.0,
            "isTransformer": False,
        })

    # Transformers travel as branches too — the frontend draws them the same
    # way — with ids offset so they stay distinguishable.
    for idx, row in net.trafo.iterrows():
        live = has and idx in net.res_trafo.index and bool(row.in_service)
        lines.append({
            "id": int(1000 + idx),
            "fromBus": int(row.hv_bus),
            "toBus": int(row.lv_bus),
            "loadingPercent": float(net.res_trafo.at[idx, "loading_percent"]) if live else 0.0,
            "maxLoadingMva": float(row.sn_mva) if row.sn_mva and row.sn_mva > 0 else 0.0,
            "inService": bool(row.in_service),
            "pFromMw": float(net.res_trafo.at[idx, "p_hv_mw"]) if live else 0.0,
            "qFromMvar": float(net.res_trafo.at[idx, "q_hv_mvar"]) if live else 0.0,
            "isTransformer": True,
        })

    generators = []
    for idx, row in net.gen.iterrows():
        live = has and idx in net.res_gen.index
        generators.append({
            "id": int(idx),
            "bus": int(row.bus),
            "pMw": float(net.res_gen.at[idx, "p_mw"]) if live else 0.0,
            "qMvar": float(net.res_gen.at[idx, "q_mvar"]) if live else 0.0,
            "inService": bool(row.in_service),
            "pMaxMw": float(row.max_p_mw) if "max_p_mw" in row and row.max_p_mw == row.max_p_mw else 0.0,
        })
    for idx, row in net.ext_grid.iterrows():
        live = has and idx in net.res_ext_grid.index
        generators.append({
            "id": int(1000 + idx),
            "bus": int(row.bus),
            "pMw": float(net.res_ext_grid.at[idx, "p_mw"]) if live else 0.0,
            "qMvar": float(net.res_ext_grid.at[idx, "q_mvar"]) if live else 0.0,
            "inService": bool(row.in_service),
            "pMaxMw": 0.0,
        })

    total_load = float(net.res_load.p_mw.sum()) if has else 0.0
    total_gen = float(net.res_gen.p_mw.sum() + net.res_ext_grid.p_mw.sum()) if has else 0.0
    total_loss = float(net.res_line.pl_mw.sum() + net.res_trafo.pl_mw.sum()) if has else 0.0

    return {
        "converged": bool(converged),
        "name": str(net.name) if getattr(net, "name", None) else "network",
        "baseMva": float(net.sn_mva) if hasattr(net, "sn_mva") else 100.0,
        "buses": buses,
        "lines": lines,
        "generators": generators,
        "totalLoadMw": total_load,
        "totalGenMw": total_gen,
        "totalLossMw": total_loss,
    }


def solveImpl(spec):
    """EffectFn1 SolveSpec SolveOutcome — called saturated, so a plain def."""
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

    try:
        pp.runpp(net)
        converged = True
    except Exception:
        converged = False

    return _marshal(net, converged)
