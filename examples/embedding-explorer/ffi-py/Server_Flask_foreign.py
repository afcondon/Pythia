# Flask FFI implementation for PurePy
# Requires: pip install flask flask-cors

from flask import Flask, request, jsonify as flask_jsonify
from functools import wraps
import re

# Counter for unique endpoint names
_endpoint_counter = [0]

def _make_endpoint(prefix, path):
    """Generate unique endpoint name from path"""
    _endpoint_counter[0] += 1
    # Sanitize path to make valid Python identifier
    safe_path = re.sub(r'[^a-zA-Z0-9]', '_', path)
    return f"{prefix}_{safe_path}_{_endpoint_counter[0]}"

# Marker class for delayed JSON serialization
# This allows jsonify to be called at route registration time
# but actual Flask jsonification happens inside request context
class JsonResponse:
    def __init__(self, data):
        self.data = data

# Create Flask app
def createApp(name):
    def effect():
        return Flask(name)
    return effect

# Route registration (generic)
def routeImpl(app, path, handler):
    endpoint = _make_endpoint('route', path)
    def effect():
        def route_handler():
            result = handler()  # Run the Effect
            if isinstance(result, JsonResponse):
                return flask_jsonify(_to_json_safe(result.data))
            return result
        app.add_url_rule(path, endpoint, route_handler)
        return None
    return effect

# GET route
def getImpl(app, path, handler):
    endpoint = _make_endpoint('get', path)
    def effect():
        def get_handler():
            result = handler()  # Run the Effect
            # If result is a JsonResponse marker, jsonify it now (inside request context)
            if isinstance(result, JsonResponse):
                return flask_jsonify(_to_json_safe(result.data))
            return result
        app.add_url_rule(path, endpoint, get_handler, methods=['GET'])
        return None
    return effect

# POST route with request access
def postImpl(app, path, handler):
    endpoint = _make_endpoint('post', path)
    def effect():
        def post_handler():
            result = handler(request)()  # Pass request, run Effect
            if isinstance(result, JsonResponse):
                return flask_jsonify(_to_json_safe(result.data))
            return result
        app.add_url_rule(path, endpoint, post_handler, methods=['POST'])
        return None
    return effect

# Convert to JSON response (returns a marker, actual jsonification happens in route handler)
def jsonify(data):
    # Return a marker that will be converted to Flask response inside route handler
    return JsonResponse(data)

def _to_json_safe(val):
    """Recursively convert PureScript runtime values to JSON-safe Python.
    The rebooted backend's representation makes this precise where the
    first incarnation needed a heuristic: PS Arrays are Python LISTS,
    ADT values are Python TUPLES (tag at [0]) - an Array of Strings is
    no longer mistakable for a tagged value."""
    if isinstance(val, dict):
        return {k: _to_json_safe(v) for k, v in val.items()}
    elif isinstance(val, tuple):
        # Tagged ADT like ("Just", value) or ("Node", left, val, right)
        tag = val[0]
        if len(val) == 1:
            return {"tag": tag}
        elif len(val) == 2:
            return {"tag": tag, "value": _to_json_safe(val[1])}
        else:
            return {"tag": tag, "values": [_to_json_safe(v) for v in val[1:]]}
    elif isinstance(val, list):
        return [_to_json_safe(v) for v in val]
    else:
        return val

# Get JSON from request body
def getRequestJson(req):
    def effect():
        return req.get_json()
    return effect

# Run the Flask app
def runImpl(app, port):
    def effect():
        print(f"Starting Flask server on http://localhost:{port}")
        app.run(port=port, debug=True, use_reloader=False)
    return effect

# Run with host option
def runWithOptionsImpl(app, host, port):
    def effect():
        print(f"Starting Flask server on http://{host}:{port}")
        app.run(host=host, port=port, debug=True, use_reloader=False)
    return effect

# Enable CORS
def cors(app):
    def effect():
        try:
            from flask_cors import CORS
            CORS(app)
            print("CORS enabled")
        except ImportError:
            print("Warning: flask-cors not installed, CORS not enabled")
            print("Install with: pip install flask-cors")
    return effect
