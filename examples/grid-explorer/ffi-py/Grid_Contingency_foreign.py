# N-1 Contingency analysis using pandapower
# Requires: pip install pandapower

import pandapower as pp
import pandapower.networks as pn
import numpy as np

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


def _classify_severity(max_loading, min_voltage, converged):
    """Classify contingency severity."""
    if not converged:
        return "critical"
    if max_loading > 100 or min_voltage < 0.9:
        return "critical"
    if max_loading > 80 or min_voltage < 0.95:
        return "warning"
    return "safe"


def _run_single_contingency(net, line_id):
    """Run power flow with one line out of service."""
    # Save original state
    original_state = net.line.at[line_id, 'in_service']

    # Take line out of service
    net.line.at[line_id, 'in_service'] = False

    try:
        pp.runpp(net)
        converged = True

        # Find worst loading
        max_loading = 0.0
        worst_line = -1
        for idx in net.res_line.index:
            if net.line.at[idx, 'in_service']:
                loading = net.res_line.at[idx, 'loading_percent']
                if loading > max_loading:
                    max_loading = loading
                    worst_line = int(idx)

        # Find worst voltage
        min_voltage = 2.0
        worst_bus = -1
        for idx in net.res_bus.index:
            voltage = net.res_bus.at[idx, 'vm_pu']
            if voltage < min_voltage:
                min_voltage = voltage
                worst_bus = int(idx)

    except Exception as e:
        converged = False
        max_loading = 999.0
        worst_line = -1
        min_voltage = 0.0
        worst_bus = -1

    # Restore original state
    net.line.at[line_id, 'in_service'] = original_state

    severity = _classify_severity(max_loading, min_voltage, converged)

    return {
        'lineId': int(line_id),
        'lineName': net.line.at[line_id, 'name'] if 'name' in net.line.columns else f"Line {line_id}",
        'converged': converged,
        'maxLoading': float(max_loading),
        'worstOverloadLine': worst_line,
        'minVoltage': float(min_voltage),
        'worstVoltageBus': worst_bus,
        'severity': severity
    }


def runContingency(network_dict):
    """Run N-1 contingency analysis."""
    def effect():
        case_name = network_dict.get('name', 'case14')
        net = _get_case(case_name)

        cases = []
        critical_count = 0
        warning_count = 0
        safe_count = 0

        for line_id in net.line.index:
            if not net.line.at[line_id, 'in_service']:
                continue

            result = _run_single_contingency(net, line_id)
            cases.append(result)

            if result['severity'] == 'critical':
                critical_count += 1
            elif result['severity'] == 'warning':
                warning_count += 1
            else:
                safe_count += 1

        # Sort by severity (critical first, then warning, then safe)
        severity_order = {'critical': 0, 'warning': 1, 'safe': 2}
        cases.sort(key=lambda x: (severity_order[x['severity']], -x['maxLoading']))

        return {
            'caseName': case_name,
            'totalLines': len(net.line),
            'criticalCount': critical_count,
            'warningCount': warning_count,
            'safeCount': safe_count,
            'cases': cases
        }
    return effect


def runSingleContingency(network_dict):
    """Run contingency for a single line."""
    def inner(line_id):
        def effect():
            case_name = network_dict.get('name', 'case14')
            net = _get_case(case_name)
            return _run_single_contingency(net, line_id)
        return effect
    return inner
