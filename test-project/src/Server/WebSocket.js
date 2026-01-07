// FFI stub for PureScript compiler - actual implementation is in WebSocket.py
// This module is designed for the Python backend only.

const pythonOnly = (name) => {
  throw new Error(
    `Server.WebSocket.${name}: This module is for the Python backend only. ` +
    `Use Web.WebSocket for browser-side WebSocket operations.`
  );
};

export const serveImpl = (port, handler) => pythonOnly("serve");
export const stop = (server) => pythonOnly("stop");
export const sendText = (conn) => (msg) => pythonOnly("sendText");
export const receive = (conn) => pythonOnly("receive");
export const close = (conn) => pythonOnly("close");
export const closeWithCodeImpl = (conn, code, reason) => pythonOnly("closeWithCode");
export const isOpen = (conn) => () => pythonOnly("isOpen");
export const getRemoteAddress = (conn) => () => pythonOnly("getRemoteAddress");
export const getPath = (conn) => () => pythonOnly("getPath");
export const broadcastImpl = (server, msg) => pythonOnly("broadcast");
export const broadcastExceptImpl = (server, except, msg) => pythonOnly("broadcastExcept");
export const getConnections = (server) => () => pythonOnly("getConnections");
