# Pythia "Embedding Explorer" backend — PureScript→Python (purepy) output served
# via Flask (umap-learn computes the projection). Build-once-ship: this image
# bundles the prebuilt output-py; the PS→Python compile is a separate lifecycle
# phase (spago build + purepy), not done here.
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Prebuilt compiled output (self-contained: runtime + FFI shims baked in).
COPY output-py ./output-py

# Flask binds 0.0.0.0:8081 (runImpl patched to bind all interfaces so the edge
# container can reach it; loopback-only would be unreachable across containers).
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD python3 -c "import socket; socket.create_connection(('127.0.0.1', 8081), 5).close()" || exit 1

CMD ["python3", "output-py"]
