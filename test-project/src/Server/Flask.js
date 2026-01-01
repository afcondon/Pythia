// FFI stub for PureScript compiler - actual implementation is in Flask.py
export const createApp = name => () => { throw new Error("Python FFI only"); };
export const routeImpl = (app, path, handler) => () => {};
export const getImpl = (app, path, handler) => () => {};
export const postImpl = (app, path, handler) => () => {};
export const jsonify = data => data;
export const getRequestJson = req => () => ({});
export const runImpl = (app, port) => () => {};
export const runWithOptionsImpl = (app, host, port) => () => {};
export const cors = app => () => {};
