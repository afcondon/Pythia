# Cascading failure simulation using pandapower
# Requires: pip install pandapower

import pandapower as pp
import pandapower.networks as pn
import numpy as np
from copy import deepcopy

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


def _find_islands(net):
    """Find buses not connected to any slack bus."""
    from collections import deque

    # Build adjacency from in-service lines and trafos
    adj = {idx: set() for idx in net.bus.index}

    for _, row in net.line[net.line.in_service].iterrows():
        adj[row.from_bus].add(row.to_bus)
        adj[row.to_bus].add(row.from_bus)

    for _, row in net.trafo[net.trafo.in_service].iterrows():
        adj[row.hv_bus].add(row.lv_bus)
        adj[row.lv_bus].add(row.hv_bus)

    # BFS from slack buses
    slack_buses = set(net.ext_grid.bus.values)
    visited = set()
    queue = deque(slack_buses)

    while queue:
        bus = queue.popleft()
        if bus in visited:
            continue
        visited.add(bus)
        for neighbor in adj.get(bus, []):
            if neighbor not in visited:
                queue.append(neighbor)

    # Buses not visited are islanded
    islanded = [int(idx) for idx in net.bus.index if idx not in visited]
    return islanded


def _shed_load_at_buses(net, bus_ids):
    """Take loads at specified buses out of service."""
    shed_mw = 0.0
    for idx in net.load.index:
        if net.load.at[idx, 'bus'] in bus_ids and net.load.at[idx, 'in_service']:
            shed_mw += net.load.at[idx, 'p_mw']
            net.load.at[idx, 'in_service'] = False
    return shed_mw


def simulateCascade(network_dict):
    """Simulate cascading failure."""
    def inner(params):
        def effect():
            case_name = network_dict.get('name', 'case14')
            net = _get_case(case_name)

            initial_failures = params.get('initialFailures', [])
            threshold = params.get('loadingThreshold', 100.0)
            max_iter = params.get('maxIterations', 10)

            steps = []
            total_load_lost = 0.0
            total_lines_lost = 0
            all_failed_lines = set()

            # Apply initial failures
            for line_id in initial_failures:
                if line_id < len(net.line):
                    net.line.at[line_id, 'in_service'] = False
                    all_failed_lines.add(line_id)

            total_lines_lost = len(initial_failures)

            for iteration in range(max_iter):
                # Run power flow
                try:
                    pp.runpp(net, enforce_q_lims=True)
                    converged = True
                except:
                    converged = False
                    break

                # Find islanded buses and shed their load
                islanded = _find_islands(net)
                shed_mw = _shed_load_at_buses(net, islanded)
                total_load_lost += shed_mw

                # Find overloaded lines
                overloaded = []
                newly_failed = []

                for idx in net.line.index:
                    if net.line.at[idx, 'in_service'] and idx in net.res_line.index:
                        loading = net.res_line.at[idx, 'loading_percent']
                        if loading > threshold:
                            overloaded.append(int(idx))
                            if idx not in all_failed_lines:
                                # Trip the line
                                net.line.at[idx, 'in_service'] = False
                                all_failed_lines.add(idx)
                                newly_failed.append(int(idx))

                total_lines_lost += len(newly_failed)

                steps.append({
                    'iteration': iteration,
                    'failedLines': newly_failed,
                    'overloadedLines': overloaded,
                    'islandedBuses': islanded,
                    'loadShedMw': float(shed_mw),
                    'totalLoadLostMw': float(total_load_lost)
                })

                # Check if cascade has stabilized
                if len(newly_failed) == 0 and len(islanded) == 0:
                    break

            # Convert final network state
            # Import works in both source dir (Grid.PowerFlow) and output-py (grid_power_flow_foreign)
            try:
                from grid_power_flow_foreign import _network_to_dict
            except ImportError:
                from Grid_PowerFlow_foreign import _network_to_dict
            final_network = _network_to_dict(net)

            return {
                'converged': converged,
                'steps': steps,
                'finalNetwork': final_network,
                'totalLoadLostMw': float(total_load_lost),
                'totalLinesLost': total_lines_lost,
                'cascadeDepth': len(steps)
            }
        return effect
    return inner
