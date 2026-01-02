// FFI stub for PureScript compilation
// This module is designed for the Python backend only.
// All functions throw errors to fail fast if accidentally used in JavaScript.

const pythonOnly = (name) => {
  throw new Error(
    `Control.Monad.Asyncio.${name}: This module is for the Python backend only. ` +
    `Use Effect.Aff for JavaScript async operations.`
  );
};

export const pureAsyncio = (_a) => pythonOnly("pureAsyncio");
export const bindAsyncio = (_ma) => (_f) => pythonOnly("bindAsyncio");
export const mapAsyncio = (_f) => (_ma) => pythonOnly("mapAsyncio");
export const applyAsyncio = (_mf) => (_ma) => pythonOnly("applyAsyncio");
export const runAsyncio = (_ma) => () => pythonOnly("runAsyncio");
export const sleep = (_ms) => pythonOnly("sleep");
export const forkAsyncio = (_ma) => pythonOnly("forkAsyncio");
export const awaitTask = (_task) => pythonOnly("awaitTask");
export const cancelTask = (_task) => pythonOnly("cancelTask");
export const parallelImpl = (_asyncios) => pythonOnly("parallelImpl");
export const raceAsyncio = (_ma) => (_mb) => pythonOnly("raceAsyncio");
export const attemptAsyncio = (_ma) => pythonOnly("attemptAsyncio");
export const throwErrorAsyncio = (_msg) => pythonOnly("throwErrorAsyncio");
export const catchErrorAsyncio = (_ma) => (_handler) => pythonOnly("catchErrorAsyncio");
export const bracketAsyncio = (_acquire) => (_release) => (_use) => pythonOnly("bracketAsyncio");
export const liftEffectAsyncio = (_eff) => pythonOnly("liftEffectAsyncio");
