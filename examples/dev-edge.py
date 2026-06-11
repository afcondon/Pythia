#!/usr/bin/env python3
"""
Local stand-in for hypo-punter's edge proxy, so the UNCHANGED showcase
frontends can be tested against the rebooted backend's example servers
without Docker or the MacMini.

Routes (mirroring the docker-compose edge):
    /ee/api/*  -> http://localhost:8081/api/*   (examples/embedding-explorer)
    /ge/api/*  -> http://localhost:8082/api/*   (examples/grid-explorer)
    /ee/*      -> hypo-punter/ee-website/public/*
    /ge/*      -> hypo-punter/ge-website/public/*
    /          -> a minimal index linking both

Usage:
    python3 output-py &           # in each example dir (8081, 8082)
    python3 examples/dev-edge.py  # then open http://localhost:9090/
Stdlib only.
"""

import sys
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 9090
SHOWCASES = Path(__file__).resolve().parents[3] / "purescript-hylograph-showcases" / "hypo-punter"
SITES = {
    "ee": (SHOWCASES / "ee-website" / "public", "http://localhost:8081"),
    "ge": (SHOWCASES / "ge-website" / "public", "http://localhost:8082"),
}

INDEX = """<!doctype html><meta charset="utf-8"><title>purepy showcases (local)</title>
<body style="font-family: system-ui; max-width: 40rem; margin: 4rem auto;">
<h1>purepy showcases — local dev edge</h1>
<ul>
<li><a href="/ee/">Embedding Explorer</a> (backend :8081)</li>
<li><a href="/ge/">Grid Explorer</a> (backend :8082)</li>
</ul>
<p>Backends must be running: <code>python3 output-py</code> in each example dir.</p>
"""

CONTENT_TYPES = {".html": "text/html", ".js": "application/javascript",
                 ".css": "text/css", ".json": "application/json",
                 ".svg": "image/svg+xml", ".png": "image/png"}


class Edge(BaseHTTPRequestHandler):
    def do_GET(self):
        self.route("GET")

    def do_POST(self):
        self.route("POST")

    def route(self, method):
        parts = self.path.lstrip("/").split("/", 1)
        site = parts[0]
        rest = parts[1] if len(parts) > 1 else ""
        if site not in SITES:
            return self.reply(200, "text/html", INDEX.encode())
        public, backend = SITES[site]
        if rest.startswith("api"):
            return self.proxy(method, backend + "/" + rest.split("?")[0], )
        # static
        rel = rest.split("?")[0] or "index.html"
        f = (public / rel).resolve()
        if public.resolve() not in f.parents and f != public.resolve():
            return self.reply(403, "text/plain", b"forbidden")
        if f.is_dir():
            f = f / "index.html"
        if not f.is_file():
            return self.reply(404, "text/plain", b"not found")
        ctype = CONTENT_TYPES.get(f.suffix, "application/octet-stream")
        return self.reply(200, ctype, f.read_bytes())

    def proxy(self, method, url):
        body = None
        if method == "POST":
            n = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(n) if n else None
        req = urllib.request.Request(url, data=body, method=method)
        if self.headers.get("Content-Type"):
            req.add_header("Content-Type", self.headers["Content-Type"])
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                self.reply(r.status, r.headers.get("Content-Type", "application/json"),
                           r.read())
        except urllib.error.HTTPError as e:
            self.reply(e.code, "text/plain", e.read())
        except Exception as e:
            self.reply(502, "text/plain",
                       f"backend {url} unreachable: {e}".encode())

    def reply(self, status, ctype, data):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        print(f"  {self.command} {self.path}", file=sys.stderr)


if __name__ == "__main__":
    for name, (public, backend) in SITES.items():
        ok = "ok" if public.is_dir() else "MISSING"
        print(f"/{name}/ -> {public} [{ok}], api -> {backend}")
    print(f"dev edge on http://localhost:{PORT}/")
    ThreadingHTTPServer(("127.0.0.1", PORT), Edge).serve_forever()
