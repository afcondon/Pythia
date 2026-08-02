# Native reference implementation of the Grid Explorer analysis.
#
# NO PURESCRIPT. This is the control: the same three answers — N-1 contingency,
# topology/loading metrics, cascading failure — computed the way a competent
# pandapower user would write them if nobody had ever mentioned a type system.
#
# It exists for two reasons, and the second is the more important one.
#
#   1. PERFORMANCE. It is the theoretical-max target. Without it we can only
#      say where time goes *inside* the polyglot architecture, which is blind
#      to the failure mode where the FFI seam pushes you into calling the
#      library badly: foreign time balloons, foreign *share* rises, and the
#      in-process instrumentation reports "the library dominates, the
#      architecture is clean" while the thing runs ten times slower than it
#      should.
#
#   2. CORRECTNESS. If pure-pandapower flags the same branches critical under
#      N-1, that is a far stronger check than any smoke test. It is the same
#      move the backends make one level down, where the differential corpus
#      proves meaning by diffing against a JavaScript reference.
#
# The straw-man risk is real and we are the ones writing both sides, so: this
# is written first, using pandapower's and networkx's intended entry points and
# vectorised reductions rather than a transliteration of the PureScript. If a
# number here looks flattering to the polyglot version, that is a reason to
# look harder at this file, not a result.
#
# Semantics are fixed by the exhibit and must match exactly for the
# correctness comparison to mean anything:
#
#   * Branches are lines AND transformers; transformers carry id 1000 + index.
#   * Worst loading is over IN-SERVICE branches only (an open branch reports
#     0 % and would otherwise look healthy).
#   * Worst voltage is over all buses, skipping NaN — islanded buses have no
#     voltage, and must not be read as the minimum. Hence nanmin, not min.
#   * A non-convergent solve is Critical: no steady state is worse than any
#     particular overload, not better.

import copy
import time
from dataclasses import dataclass, field

import networkx as nx
import numpy as np
import pandapower as pp
import pandapower.networks as pn

CASES = {
    "case14": pn.case14,
    "case30": pn.case30,
    "case57": pn.case57,
    "case118": pn.case118,
    "case_ieee30": pn.case_ieee30,
}

# Standard planning limits: 100 % of thermal rating, and the ±5 %/±10 % band.
CRITICAL_LOADING = 100.0
WARNING_LOADING = 80.0
CRITICAL_VOLTAGE = 0.90
WARNING_VOLTAGE = 0.95

TRAFO_ID_OFFSET = 1000


@dataclass
class Clock:
    """Wall clock split into time inside pandapower and everything else.

    `foreign` is the number the polyglot side has to be compared against: if
    the exhibit spends five times longer inside pandapower than this does for
    the same answer, the seam deformed the computation.
    """

    total: float = 0.0
    foreign: float = 0.0
    solves: int = 0
    _t0: float = field(default=0.0, repr=False)

    def start(self):
        self._t0 = time.perf_counter()

    def stop(self):
        self.total = time.perf_counter() - self._t0

    @property
    def core(self):
        return self.total - self.foreign


_BASE_CACHE = {}


def build_net(case_name, load_factor):
    """The intact network at a load factor.

    The reference network is constructed once and copied thereafter. This is
    both the idiomatic thing for a long-running service and, more to the point,
    what the seam does (`Grid_Solver_foreign._BASE_CACHE`) — and it matters a
    great deal to the comparison. Constructing `case30` from scratch costs
    ~150 ms, which is two orders of magnitude more than the analysis it feeds.
    Left uncached here it dominated the reference's own wall clock and made the
    polyglot version look *faster* than native on two of three scenarios. A
    flattering number is a reason to look at the reference, not a result.
    """
    if case_name not in CASES:
        raise ValueError(f"Unknown case: {case_name}. Available: {sorted(CASES)}")
    if case_name not in _BASE_CACHE:
        net = CASES[case_name]()
        net.name = case_name
        _BASE_CACHE[case_name] = net
    net = copy.deepcopy(_BASE_CACHE[case_name])
    if load_factor != 1.0:
        net.load.p_mw = net.load.p_mw * load_factor
        net.load.q_mvar = net.load.q_mvar * load_factor
    return net


def _run(net, clock):
    """One AC power flow. Returns convergence; times the library call."""
    t = time.perf_counter()
    try:
        pp.runpp(net)
        ok = True
    except Exception:
        ok = False
    clock.foreign += time.perf_counter() - t
    clock.solves += 1
    return ok


def _worst_loading(net):
    """Heaviest loading over in-service branches, and which branch carries it.

    Vectorised: two masked nanmax reductions over the result frames rather than
    a per-row walk. This is the difference the reference is here to expose.
    """
    best_val, best_id = 0.0, -1

    live = net.line.in_service.values
    if live.any():
        vals = net.res_line.loading_percent.values[live]
        if vals.size and not np.all(np.isnan(vals)):
            i = int(np.nanargmax(vals))
            if vals[i] > best_val:
                best_val = float(vals[i])
                best_id = int(net.line.index[live][i])

    live_t = net.trafo.in_service.values
    if live_t.any():
        vals = net.res_trafo.loading_percent.values[live_t]
        if vals.size and not np.all(np.isnan(vals)):
            i = int(np.nanargmax(vals))
            if vals[i] > best_val:
                best_val = float(vals[i])
                best_id = TRAFO_ID_OFFSET + int(net.trafo.index[live_t][i])

    return best_val, best_id


def _worst_voltage(net):
    """Lowest bus voltage, skipping buses with no voltage (islanded → NaN)."""
    vals = net.res_bus.vm_pu.values
    if vals.size == 0 or np.all(np.isnan(vals)):
        return 2.0, -1
    i = int(np.nanargmin(vals))
    return float(vals[i]), int(net.res_bus.index[i])


def classify(converged, max_loading, min_voltage):
    if not converged:
        return "critical"
    if max_loading > CRITICAL_LOADING:
        return "critical"
    if min_voltage < CRITICAL_VOLTAGE:
        return "critical"
    if max_loading > WARNING_LOADING:
        return "warning"
    if min_voltage < WARNING_VOLTAGE:
        return "warning"
    return "safe"


def _branch_slots(net):
    """Every in-service branch as (id, table, index) — lines then transformers."""
    slots = [
        (int(i), "line", int(i))
        for i in net.line.index
        if bool(net.line.at[i, "in_service"])
    ]
    slots += [
        (TRAFO_ID_OFFSET + int(i), "trafo", int(i))
        for i in net.trafo.index
        if bool(net.trafo.at[i, "in_service"])
    ]
    return slots


# ---------------------------------------------------------------- contingency


def contingency(case_name="case30", load_factor=0.7):
    """N-1: open each branch in turn, classify what is left standing.

    Written the idiomatic pandapower way — one network, `in_service` toggled
    and restored around each solve. No per-case deep copy, and nothing is
    marshalled: the verdict needs four scalars, so four scalars are what get
    read out of the result frames.
    """
    clock = Clock()
    clock.start()

    net = build_net(case_name, load_factor)
    intact_ok = _run(net, clock)
    if not intact_ok:
        raise RuntimeError(f"{case_name} does not converge intact at lf={load_factor}")

    cases = []
    for branch_id, table, idx in _branch_slots(net):
        frame = getattr(net, table)
        frame.at[idx, "in_service"] = False
        ok = _run(net, clock)
        if ok:
            max_loading, worst_line = _worst_loading(net)
            min_voltage, worst_bus = _worst_voltage(net)
        else:
            max_loading, worst_line = 0.0, -1
            min_voltage, worst_bus = 2.0, -1
        frame.at[idx, "in_service"] = True

        cases.append(
            {
                "lineId": branch_id,
                "isTransformer": table == "trafo",
                "converged": ok,
                "maxLoading": max_loading,
                "worstOverloadLine": worst_line,
                "minVoltage": min_voltage,
                "worstVoltageBus": worst_bus,
                "severity": classify(ok, max_loading, min_voltage),
            }
        )

    rank = {"critical": 0, "warning": 1, "safe": 2}
    cases.sort(key=lambda c: (rank[c["severity"]], -c["maxLoading"]))

    clock.stop()
    counts = {s: sum(1 for c in cases if c["severity"] == s) for s in rank}
    return (
        {
            "caseName": case_name,
            "loadFactor": load_factor,
            "totalBranches": len(cases),
            "criticalCount": counts["critical"],
            "warningCount": counts["warning"],
            "safeCount": counts["safe"],
            "cases": cases,
        },
        clock,
    )


# -------------------------------------------------------------------- metrics


def _graph(net, in_service_only=False):
    """Bus graph. Transformers are edges too — they connect buses."""
    g = nx.Graph()
    g.add_nodes_from(int(i) for i in net.bus.index)
    lines = net.line[net.line.in_service] if in_service_only else net.line
    trafos = net.trafo[net.trafo.in_service] if in_service_only else net.trafo
    g.add_edges_from(zip(lines.from_bus.astype(int), lines.to_bus.astype(int)))
    g.add_edges_from(zip(trafos.hv_bus.astype(int), trafos.lv_bus.astype(int)))
    return g


def metrics(case_name="case30", load_factor=0.7):
    """Topology and loading metrics for the intact network."""
    clock = Clock()
    clock.start()

    net = build_net(case_name, load_factor)
    ok = _run(net, clock)
    if not ok:
        raise RuntimeError(f"{case_name} does not converge intact at lf={load_factor}")

    g = _graph(net)
    degrees = [d for _, d in g.degree()]
    components = list(nx.connected_components(g))

    live_line = net.res_line.loading_percent.values[net.line.in_service.values]
    live_trafo = net.res_trafo.loading_percent.values[net.trafo.in_service.values]
    loadings = np.concatenate([live_line, live_trafo])

    total_load = float(net.res_load.p_mw.sum())
    total_gen = float(net.res_gen.p_mw.sum() + net.res_ext_grid.p_mw.sum())
    total_loss = float(net.res_line.pl_mw.sum() + net.res_trafo.pl_mw.sum())

    n_live_branches = int(net.line.in_service.sum() + net.trafo.in_service.sum())
    n_gens = int(net.gen.in_service.sum() + net.ext_grid.in_service.sum())

    result = {
        "caseName": case_name,
        "topology": {
            "busCount": int(len(net.bus)),
            "branchCount": n_live_branches,
            "generatorCount": n_gens,
            "averageDegree": float(np.mean(degrees)) if degrees else 0.0,
            "maxDegree": int(max(degrees)) if degrees else 0,
            "diameter": int(nx.diameter(g)) if len(components) == 1 else 0,
            "componentCount": len(components),
            "isConnected": len(components) <= 1,
        },
        "loading": {
            "maxLoadingPercent": float(np.nanmax(loadings)) if loadings.size else 0.0,
            "meanLoadingPercent": float(np.nanmean(loadings)) if loadings.size else 0.0,
            "medianLoadingPercent": (
                float(np.median(loadings)) if loadings.size else 0.0
            ),
            "overloadedCount": int(np.sum(loadings > 100.0)),
            "totalLoadMw": total_load,
            "totalGenMw": total_gen,
            "totalLossMw": total_loss,
            "lossPercent": (total_loss / total_gen * 100.0) if total_gen > 0 else 0.0,
        },
    }

    clock.stop()
    return result, clock


# -------------------------------------------------------------------- cascade

LOADING_TRIP = 100.0
MAX_ROUNDS = 10


def _apply_outages(net, lines_out, loads_out_buses):
    net.line.in_service = True
    net.trafo.in_service = True
    net.load.in_service = True
    for bid in lines_out:
        if bid >= TRAFO_ID_OFFSET:
            t = bid - TRAFO_ID_OFFSET
            if t in net.trafo.index:
                net.trafo.at[t, "in_service"] = False
        elif bid in net.line.index:
            net.line.at[bid, "in_service"] = False
    if loads_out_buses:
        mask = net.load.bus.astype(int).isin(list(loads_out_buses))
        net.load.loc[mask, "in_service"] = False


def _overloaded(net):
    """In-service branches past the trip threshold."""
    out = []
    live = net.line.in_service.values
    vals = net.res_line.loading_percent.values
    for i, idx in enumerate(net.line.index):
        if live[i] and vals[i] > LOADING_TRIP:
            out.append(int(idx))
    live_t = net.trafo.in_service.values
    vals_t = net.res_trafo.loading_percent.values
    for i, idx in enumerate(net.trafo.index):
        if live_t[i] and vals_t[i] > LOADING_TRIP:
            out.append(TRAFO_ID_OFFSET + int(idx))
    return out


def _islanded(net, lines_out):
    """Buses with no path to a slack bus once `lines_out` is open.

    networkx's own connectivity, which is what this graph work is for.
    """
    g = nx.Graph()
    g.add_nodes_from(int(i) for i in net.bus.index)
    for idx, row in net.line.iterrows():
        if int(idx) not in lines_out:
            g.add_edge(int(row.from_bus), int(row.to_bus))
    for idx, row in net.trafo.iterrows():
        if TRAFO_ID_OFFSET + int(idx) not in lines_out:
            g.add_edge(int(row.hv_bus), int(row.lv_bus))

    slack = set(int(b) for b in net.ext_grid.bus.values)
    reachable = set()
    for s in slack:
        if s in g:
            reachable |= nx.node_connected_component(g, s)
    return sorted(int(b) for b in net.bus.index if int(b) not in reachable)


def cascade(case_name="case30", load_factor=0.7, initial_failures=(35,)):
    """Trip what is overloaded, shed what is islanded, re-solve, repeat."""
    clock = Clock()
    clock.start()

    net = build_net(case_name, load_factor)
    out = list(dict.fromkeys(int(i) for i in initial_failures))
    shed_buses = []
    steps = []
    lost = 0.0

    _apply_outages(net, out, shed_buses)
    ok = _run(net, clock)

    for rnd in range(MAX_ROUNDS):
        if not ok:
            break
        overloaded = _overloaded(net)
        tripped = [i for i in overloaded if i not in out]
        islanded = [
            b for b in _islanded(net, out + tripped) if b not in shed_buses
        ]
        if not tripped and not islanded:
            break

        load_by_bus = net.load.groupby(net.load.bus.astype(int)).p_mw.sum()
        shed = float(sum(float(load_by_bus.get(b, 0.0)) for b in islanded))

        out = out + tripped
        shed_buses = shed_buses + islanded
        lost += shed
        steps.append(
            {
                "round": rnd,
                "overloadedLines": overloaded,
                "trippedLines": tripped,
                "islandedBuses": islanded,
                "loadShedMw": shed,
                "cumulativeLoadLostMw": lost,
            }
        )

        _apply_outages(net, out, shed_buses)
        ok = _run(net, clock)

    clock.stop()
    return (
        {
            "caseName": case_name,
            "loadFactor": load_factor,
            "converged": ok,
            "initialFailures": list(initial_failures),
            "steps": steps,
            "totalLoadLostMw": lost,
            "totalLinesLost": len(out) - len(initial_failures),
            "cascadeDepth": len(steps),
        },
        clock,
    )
