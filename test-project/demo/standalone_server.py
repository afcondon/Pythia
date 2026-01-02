#!/usr/bin/env python3
"""
Standalone test server for PurePy data visualization demo.
Run this to test the frontend before compiling the PureScript version.

Usage:
    pip install flask flask-cors
    python standalone_server.py
    # Then open data-viz.html in a browser
"""

from flask import Flask, jsonify
from flask_cors import CORS
import math
import random

app = Flask(__name__)
CORS(app)

def generate_sine_data(n=100):
    """Generate sine wave data points."""
    points = []
    for i in range(n):
        x = i * (2 * math.pi) / n * 2
        y = math.sin(x) + random.gauss(0, 0.05)
        points.append({"x": x, "y": y, "label": f"sin_{i}"})
    return points

def generate_scatter_data(n=50):
    """Generate clustered scatter data."""
    points = []
    clusters = [(2, 3, "A"), (7, 8, "B"), (5, 2, "C")]
    for i in range(n):
        cx, cy, label = random.choice(clusters)
        x = cx + random.gauss(0, 1)
        y = cy + random.gauss(0, 1)
        points.append({"x": x, "y": y, "label": f"{label}_{i}"})
    return points

def compute_stats(dataset):
    """Compute statistics for a dataset."""
    if not dataset:
        return {"mean": 0, "median": 0, "stdDev": 0, "min": 0, "max": 0, "count": 0}

    y_values = [p["y"] for p in dataset]
    y_sorted = sorted(y_values)
    n = len(y_values)

    mean = sum(y_values) / n
    median = y_sorted[n // 2] if n % 2 else (y_sorted[n // 2 - 1] + y_sorted[n // 2]) / 2
    variance = sum((y - mean) ** 2 for y in y_values) / n
    std_dev = math.sqrt(variance)

    return {
        "mean": mean, "median": median, "stdDev": std_dev,
        "min": min(y_values), "max": max(y_values), "count": n
    }

@app.route('/')
def health():
    return jsonify({"message": "PurePy Data Server", "status": "running"})

@app.route('/api/sine')
def sine_data():
    dataset = generate_sine_data(100)
    stats = compute_stats(dataset)
    return jsonify({"success": True, "data": {"points": dataset, "stats": stats}, "error": ""})

@app.route('/api/scatter')
def scatter_data():
    dataset = generate_scatter_data(50)
    stats = compute_stats(dataset)
    return jsonify({"success": True, "data": {"points": dataset, "stats": stats}, "error": ""})

if __name__ == '__main__':
    print("=" * 50)
    print("  PurePy Data Server (Standalone Test)")
    print("=" * 50)
    print()
    print("Routes:")
    print("  GET /           - Health check")
    print("  GET /api/sine   - Sine wave data")
    print("  GET /api/scatter - Scatter data")
    print()
    print("Open demo/data-viz.html in a browser to see visualization")
    print()
    app.run(port=8080, debug=True)
