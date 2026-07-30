#!/usr/bin/env python3
"""
Local edge for the polyglot showcase stack — the MBP/native counterpart of the
Docker Lua edge (scuppered-ligature). Same route table, same single front door,
so the byte-identical website artifact (its root-relative /ee/, /ge/, /atlas/
links) is correct on the MBP **without Docker**, exactly as it is on the mini
**with Docker**. The home page is one artifact; each substrate supplies an edge
that satisfies its routing contract — fix is topology, not content.

This is the "edge artifact" half of the topology-contract plan; see
afc-work/docs/kb/architecture/polyglot-showcase-deploy-status.md
(§PROPOSAL "the edge is topology, preserve it locally"). Bosun's MBP fixture
(bosun/fixtures/polyglot-up) launches the backends as internal processes and this
edge as the front door (boot order: backends -> edge).

Route table (mirrors the Docker edge):
    /ee/api/*  -> embedding-explorer backend (default :8081)   [proxy]
    /ee/*      -> hypo-punter/ee-website/public               [static]
    /ge/api/*  -> grid-explorer backend (default :8082)       [proxy]
    /ge/*      -> hypo-punter/ge-website/public               [static]
    /atlas/*   -> stub until Atlas is wired locally           [static stub]
    /          -> website (static-httpd, default :3040)       [proxy — catch-all]

Everything not under /ee, /ge, /atlas (so /, /style.css, /images/*, /backends/*,
/resources/*, …) proxies to the website backend, mirroring the Docker edge where
`/` -> website:80.

Ports are overridable via flags or env (EDGE_PORT, WEBSITE_URL, EE_API, GE_API,
ATLAS_WS). Stdlib only — no dependencies on the target box.

Usage:
    # with the backends running (static-httpd :3040, ee :8081, ge :8082):
    python3 examples/dev-edge.py                 # front door on :9090
    python3 examples/dev-edge.py --port 8080 --website http://localhost:3040
    open http://localhost:9090/
"""

import argparse
import os
import sys
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

SHOWCASES = Path(__file__).resolve().parents[3] / "purescript-hylograph-showcases" / "hypo-punter"

CONTENT_TYPES = {".html": "text/html", ".js": "application/javascript",
                 ".mjs": "text/javascript", ".css": "text/css",
                 ".json": "application/json", ".svg": "image/svg+xml",
                 ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
                 ".webp": "image/webp", ".woff2": "font/woff2", ".ico": "image/x-icon"}

# Filled in by main() from flags/env.
CFG = {
    "website": "http://localhost:3040",          # the website static-httpd
    "atlas_ws": "http://localhost:3210",         # atlas service (future)
    "sites": {                                   # frontend-static + api-backend per prefix
        "ee": (SHOWCASES / "ee-website" / "public", "http://localhost:8081"),
        "ge": (SHOWCASES / "ge-website" / "public", "http://localhost:8082"),
    },
}

ATLAS_STUB = """<!doctype html><meta charset="utf-8">
<title>Stability Atlas — not wired locally yet</title>
<body style="font-family:system-ui;max-width:40rem;margin:4rem auto">
<h1>Stability Atlas</h1>
<p>The Julia exhibit isn't wired into the local edge yet. It needs the
<code>atlas-service</code> (WebSocket on :3210) plus a <code>/atlas/ws</code>
upgrade route. Deploy is paused pending the showcase rework (Marginalia Jurist
#219 note 328).</p>
</body>"""


class Edge(BaseHTTPRequestHandler):
    def do_GET(self):
        self.route("GET")

    def do_POST(self):
        self.route("POST")

    def route(self, method):
        parts = self.path.lstrip("/").split("/", 1)
        first = parts[0]
        rest = parts[1] if len(parts) > 1 else ""

        if first in CFG["sites"]:
            return self.route_site(method, first, rest)
        if first == "atlas":
            return self.route_atlas(method, rest)
        # Catch-all: everything else is the website (/, assets, /backends/*, …).
        return self.proxy(method, CFG["website"] + self.path)

    def route_site(self, method, site, rest):
        public, backend = CFG["sites"][site]
        if rest.startswith("api"):
            return self.proxy(method, backend + "/" + rest)
        # static from the frontend's public dir (served at the /<site>/ prefix)
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

    def route_atlas(self, method, rest):
        if rest.startswith("ws"):
            # WebSocket upgrade can't be proxied by stdlib http.server; stub until
            # Atlas lands (the Docker edge will do the real /atlas/ws upgrade).
            return self.reply(503, "text/plain", b"atlas websocket not wired in the local edge yet")
        return self.reply(200, "text/html", ATLAS_STUB.encode())

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
                self.reply(r.status, r.headers.get("Content-Type", "application/octet-stream"), r.read())
        except urllib.error.HTTPError as e:
            self.reply(e.code, e.headers.get("Content-Type", "text/plain"), e.read())
        except Exception as e:
            self.reply(502, "text/plain", f"backend {url} unreachable: {e}".encode())

    def reply(self, status, ctype, data):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def log_message(self, fmt, *args):
        print(f"  {self.command} {self.path}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description="Local edge for the polyglot showcase stack")
    ap.add_argument("--port", type=int, default=int(os.environ.get("EDGE_PORT", "9090")))
    ap.add_argument("--website", default=os.environ.get("WEBSITE_URL", CFG["website"]))
    ap.add_argument("--ee-api", default=os.environ.get("EE_API", CFG["sites"]["ee"][1]))
    ap.add_argument("--ge-api", default=os.environ.get("GE_API", CFG["sites"]["ge"][1]))
    ap.add_argument("--atlas-ws", default=os.environ.get("ATLAS_WS", CFG["atlas_ws"]))
    args = ap.parse_args()

    CFG["website"] = args.website.rstrip("/")
    CFG["atlas_ws"] = args.atlas_ws.rstrip("/")
    CFG["sites"]["ee"] = (CFG["sites"]["ee"][0], args.ee_api.rstrip("/"))
    CFG["sites"]["ge"] = (CFG["sites"]["ge"][0], args.ge_api.rstrip("/"))

    print(f"polyglot local edge on http://localhost:{args.port}/")
    print(f"  /            -> {CFG['website']}  [website, proxy]")
    for name, (public, backend) in CFG["sites"].items():
        ok = "ok" if public.is_dir() else "MISSING"
        print(f"  /{name}/         -> {public} [{ok}] ; /{name}/api -> {backend}")
    print(f"  /atlas/      -> stub (ws -> {CFG['atlas_ws']}, not wired)")
    ThreadingHTTPServer(("127.0.0.1", args.port), Edge).serve_forever()


if __name__ == "__main__":
    main()
