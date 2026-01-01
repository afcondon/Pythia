# Data generation FFI for DataServer demo
import math
import random

def generateSineData(n):
    """Generate sine wave data points."""
    points = []
    for i in range(n):
        x = i * (2 * math.pi) / n * 2  # Two full periods
        y = math.sin(x) + random.gauss(0, 0.05)  # Add small noise
        points.append({
            "x": x,
            "y": y,
            "label": f"sin_{i}"
        })
    return points

def generateScatterData(n):
    """Generate random scatter plot data with some clustering."""
    points = []
    clusters = [
        (2, 3, "A"),
        (7, 8, "B"),
        (5, 2, "C")
    ]
    for i in range(n):
        # Pick a random cluster
        cx, cy, label = random.choice(clusters)
        x = cx + random.gauss(0, 1)
        y = cy + random.gauss(0, 1)
        points.append({
            "x": x,
            "y": y,
            "label": f"{label}_{i}"
        })
    return points

def computeDatasetStats(dataset):
    """Compute statistics for a dataset."""
    if not dataset:
        return {
            "mean": 0.0,
            "median": 0.0,
            "stdDev": 0.0,
            "min": 0.0,
            "max": 0.0,
            "count": 0
        }

    y_values = [p["y"] for p in dataset]
    y_sorted = sorted(y_values)
    n = len(y_values)

    mean = sum(y_values) / n
    median = y_sorted[n // 2] if n % 2 == 1 else (y_sorted[n // 2 - 1] + y_sorted[n // 2]) / 2
    variance = sum((y - mean) ** 2 for y in y_values) / n
    std_dev = math.sqrt(variance)

    return {
        "mean": mean,
        "median": median,
        "stdDev": std_dev,
        "min": min(y_values),
        "max": max(y_values),
        "count": n
    }
