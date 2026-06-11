# Network metrics calculation using pandapower and networkx
# Requires: pip install pandapower networkx

import pandapower as pp
import pandapower.networks as pn
import networkx as nx
import numpy as np
from collections import defaultdict

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


def _build_graph(net):
    """Build networkx graph from pandapower network."""
    G = nx.Graph()

    # Add nodes
    for idx in net.bus.index:
        G.add_node(idx)

    # Add edges from lines
    for _, row in net.line[net.line.in_service].iterrows():
        G.add_edge(row.from_bus, row.to_bus)

    # Add edges from transformers
    for _, row in net.trafo[net.trafo.in_service].iterrows():
        G.add_edge(row.hv_bus, row.lv_bus)

    return G


def _calculate_topology_metrics(net, G):
    """Calculate topology-based metrics."""
    num_buses = len(net.bus)
    num_lines = len(net.line[net.line.in_service]) + len(net.trafo[net.trafo.in_service])
    num_generators = len(net.gen[net.gen.in_service]) + len(net.ext_grid[net.ext_grid.in_service])

    # Degree statistics
    degrees = [d for _, d in G.degree()]
    avg_degree = np.mean(degrees) if degrees else 0
    max_degree = max(degrees) if degrees else 0

    # Diameter (only if connected)
    if nx.is_connected(G) and len(G) > 1:
        diameter = nx.diameter(G)
    else:
        # For disconnected graphs, use max diameter of components
        diameter = 0
        for component in nx.connected_components(G):
            if len(component) > 1:
                subgraph = G.subgraph(component)
                diameter = max(diameter, nx.diameter(subgraph))

    return {
        'numBuses': num_buses,
        'numLines': num_lines,
        'numGenerators': num_generators,
        'avgDegree': float(avg_degree),
        'maxDegree': int(max_degree),
        'diameter': diameter
    }


def _calculate_power_metrics(net):
    """Calculate power flow metrics."""
    try:
        pp.runpp(net)
        converged = True
    except:
        converged = False

    if converged:
        total_load = float(net.res_load.p_mw.sum())
        total_gen = float(net.res_gen.p_mw.sum() + net.res_ext_grid.p_mw.sum())
        total_loss = float(net.res_line.pl_mw.sum() + net.res_trafo.pl_mw.sum())

        line_loadings = net.res_line.loading_percent.values
        avg_loading = float(np.mean(line_loadings)) if len(line_loadings) > 0 else 0
        max_loading = float(np.max(line_loadings)) if len(line_loadings) > 0 else 0

        voltages = net.res_bus.vm_pu.values
        avg_voltage = float(np.mean(voltages))
        min_voltage = float(np.min(voltages))
        max_voltage = float(np.max(voltages))
    else:
        total_load = 0
        total_gen = 0
        total_loss = 0
        avg_loading = 0
        max_loading = 0
        avg_voltage = 1.0
        min_voltage = 1.0
        max_voltage = 1.0

    return {
        'totalLoadMw': total_load,
        'totalGenMw': total_gen,
        'totalLossMw': total_loss,
        'avgLineLoading': avg_loading,
        'maxLineLoading': max_loading,
        'avgVoltagePu': avg_voltage,
        'minVoltagePu': min_voltage,
        'maxVoltagePu': max_voltage
    }


def _calculate_resilience_metrics(net, G):
    """Calculate resilience and vulnerability metrics."""
    num_buses = len(net.bus)
    num_lines = len(net.line[net.line.in_service]) + len(net.trafo[net.trafo.in_service])

    # Connectivity index (edge connectivity / max possible for tree)
    if nx.is_connected(G) and num_buses > 1:
        edge_connectivity = nx.edge_connectivity(G)
        connectivity_index = min(1.0, edge_connectivity / 2.0)  # Normalize to 0-1
    else:
        connectivity_index = 0.0

    # Redundancy ratio (actual edges / minimum spanning tree edges)
    min_edges = num_buses - 1 if num_buses > 0 else 1
    redundancy_ratio = num_lines / min_edges if min_edges > 0 else 0

    # Count critical lines (quick approximation using betweenness)
    edge_betweenness = nx.edge_betweenness_centrality(G)
    threshold = np.percentile(list(edge_betweenness.values()), 90) if edge_betweenness else 0
    critical_count = sum(1 for v in edge_betweenness.values() if v >= threshold)

    # Overall vulnerability score (inverse of resilience)
    # Low connectivity + low redundancy + many critical lines = high vulnerability
    vulnerability = 0.0
    vulnerability += (1.0 - connectivity_index) * 0.4
    vulnerability += max(0, 1.0 - redundancy_ratio / 2.0) * 0.3
    vulnerability += min(1.0, critical_count / max(1, num_lines) * 3) * 0.3

    return {
        'connectivityIndex': float(connectivity_index),
        'redundancyRatio': float(redundancy_ratio),
        'criticalLineCount': critical_count,
        'vulnerabilityScore': float(min(1.0, vulnerability))
    }


def calculateMetrics(network_dict):
    """Calculate all network metrics."""
    def effect():
        case_name = network_dict.get('name', 'case14')
        net = _get_case(case_name)
        G = _build_graph(net)

        topology = _calculate_topology_metrics(net, G)
        power = _calculate_power_metrics(net)
        resilience = _calculate_resilience_metrics(net, G)

        return {**topology, **power, **resilience}
    return effect
