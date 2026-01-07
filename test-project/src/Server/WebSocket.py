# WebSocket Server FFI implementation for PurePy
# Requires: pip install websockets
#
# All async operations return Asyncio thunks: () -> Coroutine[Any, Any, a]
# This integrates with Control.Monad.Asyncio.

import asyncio
try:
    import websockets
    from websockets.server import serve as ws_serve
    from websockets.exceptions import ConnectionClosed
except ImportError:
    raise ImportError(
        "Server.WebSocket requires the 'websockets' package. "
        "Install with: pip install websockets"
    )

# Global connection registry: server -> Set[connection]
_server_connections = {}

def serveImpl(port, handler):
    """Start WebSocket server on given port with connection handler."""
    async def coro():
        connections = set()

        async def connection_handler(websocket):
            # Register connection
            connections.add(websocket)
            try:
                # Call PureScript handler (returns Asyncio thunk)
                handler_coro = handler(websocket)
                await handler_coro()
            except ConnectionClosed:
                pass  # Normal disconnect
            except Exception as e:
                print(f"WebSocket handler error: {e}")
            finally:
                # Unregister on disconnect
                connections.discard(websocket)

        # Start server
        server = await ws_serve(
            connection_handler,
            "0.0.0.0",
            port,
            ping_interval=20,
            ping_timeout=20
        )

        # Store connections for this server
        _server_connections[id(server)] = connections

        # Attach connections set to server for easy access
        server._ps_connections = connections

        return server
    return lambda: coro()


def stop(server):
    """Stop the WebSocket server gracefully."""
    async def coro():
        server.close()
        await server.wait_closed()
        # Clean up connection registry
        if id(server) in _server_connections:
            del _server_connections[id(server)]
        return None
    return lambda: coro()


def sendText(conn):
    """Send text message to connection (curried)."""
    def go(msg):
        async def coro():
            try:
                await conn.send(msg)
            except ConnectionClosed:
                pass  # Ignore if connection already closed
            return None
        return lambda: coro()
    return go


def receive(conn):
    """Receive message from connection (blocking)."""
    async def coro():
        try:
            msg = await conn.recv()
            # Handle both text and binary
            if isinstance(msg, bytes):
                msg = msg.decode('utf-8')
            return ("Right", msg)
        except ConnectionClosed as e:
            return ("Left", f"Connection closed: {e.code}")
        except Exception as e:
            return ("Left", str(e))
    return lambda: coro()


def close(conn):
    """Close connection with normal closure (1000)."""
    async def coro():
        try:
            await conn.close()
        except Exception:
            pass  # Ignore errors on close
        return None
    return lambda: coro()


def closeWithCodeImpl(conn, code, reason):
    """Close connection with specific code and reason."""
    async def coro():
        try:
            await conn.close(code, reason)
        except Exception:
            pass
        return None
    return lambda: coro()


def isOpen(conn):
    """Check if connection is still open (Effect, not Asyncio)."""
    def effect():
        try:
            return conn.open
        except Exception:
            return False
    return effect


def getRemoteAddress(conn):
    """Get remote address as 'host:port' string (Effect)."""
    def effect():
        try:
            remote = conn.remote_address
            if remote:
                return f"{remote[0]}:{remote[1]}"
        except Exception:
            pass
        return "unknown"
    return effect


def getPath(conn):
    """Get request path (Effect)."""
    def effect():
        try:
            return conn.path or "/"
        except Exception:
            return "/"
    return effect


def broadcastImpl(server, msg):
    """Broadcast message to all connections."""
    async def coro():
        connections = getattr(server, '_ps_connections', set())
        if connections:
            # Use websockets.broadcast for efficiency
            websockets.broadcast(connections, msg)
        return None
    return lambda: coro()


def broadcastExceptImpl(server, except_conn, msg):
    """Broadcast to all except one connection."""
    async def coro():
        connections = getattr(server, '_ps_connections', set())
        targets = {c for c in connections if c != except_conn}
        if targets:
            websockets.broadcast(targets, msg)
        return None
    return lambda: coro()


def getConnections(server):
    """Get all current connections (Effect)."""
    def effect():
        return list(getattr(server, '_ps_connections', set()))
    return effect
