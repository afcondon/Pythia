// WebSocket Client FFI for browser
// This module provides Effect-based bindings to the browser WebSocket API

export const create = (url) => () => {
  return new WebSocket(url);
};

export const createWithProtocolImpl = (url, protocol) => () => {
  return new WebSocket(url, protocol);
};

// State
export const readyStateImpl = (ws) => () => ws.readyState;
export const getUrl = (ws) => () => ws.url;
export const getProtocol = (ws) => () => ws.protocol;

// Sending
export const sendText = (ws) => (msg) => () => {
  ws.send(msg);
};

// Event handlers
export const onOpen = (ws) => (handler) => () => {
  ws.onopen = () => handler();
};

export const onCloseImpl = (ws, handler) => () => {
  ws.onclose = (event) => {
    const closeEvent = {
      code: event.code,
      reason: event.reason,
      wasClean: event.wasClean
    };
    handler(closeEvent)();
  };
};

export const onMessageImpl = (ws, handler) => () => {
  ws.onmessage = (event) => handler(event)();
};

export const onErrorImpl = (ws, handler) => () => {
  ws.onerror = () => handler();
};

// Lifecycle
export const close = (ws) => () => {
  ws.close();
};

export const closeWithCodeImpl = (ws, code, reason) => () => {
  ws.close(code, reason);
};

// Event data extraction
export const getMessageData = (event) => {
  const data = event.data;
  if (typeof data === "string") {
    return data;
  } else if (data instanceof ArrayBuffer) {
    const decoder = new TextDecoder();
    return decoder.decode(data);
  }
  return String(data);
};
