# Streaming Server FFI - generates live data points
import json
import math
import random
import time

def generateDataPoint(tick):
    """Generate a data point with multiple signals for visualization."""
    def effect():
        t = tick * 0.05  # Time in seconds (50ms per tick)

        # Multiple signals for interesting visualization
        sine = math.sin(t * 2)  # Primary sine wave
        cosine = math.cos(t * 1.5) * 0.7  # Secondary cosine
        noise = random.gauss(0, 0.1)  # Gaussian noise

        # Combined signal
        value = sine + noise

        # Secondary value for scatter or dual-axis
        value2 = cosine + random.gauss(0, 0.05)

        data = {
            "type": "data",
            "tick": tick,
            "time": t,
            "timestamp": time.time() * 1000,  # JS-compatible timestamp
            "values": {
                "primary": round(value, 4),
                "secondary": round(value2, 4),
                "sine": round(sine, 4),
                "noise": round(noise, 4)
            }
        }
        return json.dumps(data)
    return effect
