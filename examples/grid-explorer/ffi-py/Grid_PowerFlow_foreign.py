# Power flow calculation using pandapower
# Requires: pip install pandapower

import copy
import pandapower as pp
import pandapower.networks as pn
import numpy as np

# Cache for loaded networks
_network_cache = {}

def _get_case(case_name):
    """Load a pandapower test case by name."""
    cases = {
        'case14': pn.case14,
        'case30': pn.case30,
        'case57': pn.case57,
        'case118': pn.case118,
        'case_ieee30': pn.case_ieee30,
    }
    if case_name not in cases:
        raise ValueError(f"Unknown case: {case_name}. Available: {list(cases.keys())}")
    return cases[case_name]()

def _calculate_layout(net):
    """Calculate node positions for visualization using simple layout."""
    n_buses = len(net.bus)

    # Simple circular layout for all networks
    positions = {}
    for i, idx in enumerate(net.bus.index):
        angle = 2 * np.pi * i / n_buses
        radius = 100 + (i % 3) * 20  # Slight variation
        positions[idx] = (np.cos(angle) * radius, np.sin(angle) * radius)

    return positions

def _network_to_dict(net, positions=None):
    """Convert pandapower network to dictionary format."""
    if positions is None:
        positions = _calculate_layout(net)

    # Check if power flow has been run
    has_results = hasattr(net, 'res_bus') and len(net.res_bus) > 0

    # Convert buses
    buses = []
    for idx, row in net.bus.iterrows():
        bus_type = "pq"  # Default
        if idx in net.ext_grid.bus.values:
            bus_type = "slack"
        elif idx in net.gen.bus.values:
            bus_type = "pv"

        pos = positions.get(idx, (0, 0))

        # Get load at this bus
        bus_loads = net.load[net.load.bus == idx]
        load_mw = bus_loads.p_mw.sum() if len(bus_loads) > 0 else 0
        load_mvar = bus_loads.q_mvar.sum() if len(bus_loads) > 0 else 0

        buses.append({
            "id": int(idx),
            "name": str(row.get('name', f"Bus {idx}") or f"Bus {idx}"),
            "busType": bus_type,
            "voltagePu": float(net.res_bus.at[idx, 'vm_pu']) if has_results else 1.0,
            "angleRad": float(np.radians(net.res_bus.at[idx, 'va_degree'])) if has_results else 0.0,
            "loadMw": float(load_mw),
            "loadMvar": float(load_mvar),
            "hasGenerator": idx in net.gen.bus.values or idx in net.ext_grid.bus.values,
            "x": float(pos[0]),
            "y": float(pos[1])
        })

    # Convert lines
    lines = []
    for idx, row in net.line.iterrows():
        loading = 0.0
        p_from = 0.0
        q_from = 0.0
        if has_results and idx in net.res_line.index:
            loading = float(net.res_line.at[idx, 'loading_percent'])
            p_from = float(net.res_line.at[idx, 'p_from_mw'])
            q_from = float(net.res_line.at[idx, 'q_from_mvar'])

        lines.append({
            "id": int(idx),
            "fromBus": int(row.from_bus),
            "toBus": int(row.to_bus),
            "loadingPercent": loading,
            "maxLoadingMva": float(row.max_i_ka * net.bus.at[row.from_bus, 'vn_kv'] * np.sqrt(3)) if row.max_i_ka > 0 else 100.0,
            "inService": bool(row.in_service),
            "pFromMw": p_from,
            "qFromMvar": q_from
        })

    # Also include transformers as "lines" for visualization
    for idx, row in net.trafo.iterrows():
        loading = 0.0
        p_from = 0.0
        q_from = 0.0
        if has_results and idx in net.res_trafo.index:
            loading = float(net.res_trafo.at[idx, 'loading_percent'])
            p_from = float(net.res_trafo.at[idx, 'p_hv_mw'])
            q_from = float(net.res_trafo.at[idx, 'q_hv_mvar'])

        lines.append({
            "id": int(1000 + idx),  # Offset to distinguish from lines
            "fromBus": int(row.hv_bus),
            "toBus": int(row.lv_bus),
            "loadingPercent": loading,
            "maxLoadingMva": float(row.sn_mva) if row.sn_mva > 0 else 100.0,
            "inService": bool(row.in_service),
            "pFromMw": p_from,
            "qFromMvar": q_from
        })

    # Convert generators
    generators = []
    for idx, row in net.gen.iterrows():
        p_mw = float(net.res_gen.at[idx, 'p_mw']) if has_results and idx in net.res_gen.index else 0.0
        q_mvar = float(net.res_gen.at[idx, 'q_mvar']) if has_results and idx in net.res_gen.index else 0.0

        generators.append({
            "id": int(idx),
            "bus": int(row.bus),
            "pMw": p_mw,
            "qMvar": q_mvar,
            "inService": bool(row.in_service),
            "pMaxMw": float(row.max_p_mw) if 'max_p_mw' in row else 100.0
        })

    # Add external grids (slack generators)
    for idx, row in net.ext_grid.iterrows():
        p_mw = float(net.res_ext_grid.at[idx, 'p_mw']) if has_results and idx in net.res_ext_grid.index else 0.0
        q_mvar = float(net.res_ext_grid.at[idx, 'q_mvar']) if has_results and idx in net.res_ext_grid.index else 0.0

        generators.append({
            "id": int(1000 + idx),  # Offset to distinguish
            "bus": int(row.bus),
            "pMw": p_mw,
            "qMvar": q_mvar,
            "inService": bool(row.in_service),
            "pMaxMw": 9999.0  # Slack bus has unlimited capacity
        })

    return {
        "name": net.name if hasattr(net, 'name') and net.name else "Power Network",
        "baseMva": float(net.sn_mva) if hasattr(net, 'sn_mva') else 100.0,
        "buses": buses,
        "lines": lines,
        "generators": generators,
        "converged": has_results
    }


def loadNetwork(case_name):
    """Load a test case network."""
    def effect():
        if case_name not in _network_cache:
            net = _get_case(case_name)
            net.name = case_name
            _network_cache[case_name] = net

        net = copy.deepcopy(_network_cache[case_name])
        return _network_to_dict(net)
    return effect


def runPowerFlow(network_dict):
    """Run AC power flow calculation."""
    def effect():
        case_name = network_dict.get('name', 'case14')
        net = _get_case(case_name)

        try:
            pp.runpp(net)
            converged = True
        except Exception as e:
            print(f"Power flow failed: {e}")
            converged = False

        network = _network_to_dict(net)
        network['converged'] = converged

        # Calculate totals
        total_load = float(net.res_load.p_mw.sum()) if converged else 0
        total_gen = float(net.res_gen.p_mw.sum() + net.res_ext_grid.p_mw.sum()) if converged else 0
        total_loss = float(net.res_line.pl_mw.sum() + net.res_trafo.pl_mw.sum()) if converged else 0

        return {
            "network": network,
            "totalLoadMw": total_load,
            "totalGenMw": total_gen,
            "totalLossMw": total_loss
        }
    return effect


def getNetworkTopology(case_name):
    """Get network topology without running power flow."""
    def effect():
        net = _get_case(case_name)
        net.name = case_name
        return _network_to_dict(net)
    return effect
