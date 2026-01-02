// FFI stub for PureScript compilation
// The Python backend provides the actual implementation via purepy_runtime

// These are placeholder implementations - they won't be used in Python
// The Python backend's runtime provides the real asyncio-based implementations

export const pureAsyncio = a => () => Promise.resolve(a);

export const bindAsyncio = ma => f => () => ma().then(a => f(a)());

export const mapAsyncio = f => ma => () => ma().then(f);

export const applyAsyncio = mf => ma => () => Promise.all([mf(), ma()]).then(([f, a]) => f(a));

export const runAsyncio = ma => () => {
  // In JS, we'd need to handle this differently
  // This is just a stub for compilation
  throw new Error("runAsyncio: Use Python backend");
};

export const sleep = ms => () => new Promise(resolve => setTimeout(() => resolve(undefined), ms));

export const forkAsyncio = ma => () => {
  const promise = ma();
  return promise; // Task is just a Promise in JS stub
};

export const awaitTask = task => () => task;

export const cancelTask = task => () => Promise.resolve(undefined);

export const parallelImpl = asyncios => () => Promise.all(asyncios.map(a => a()));

export const raceAsyncio = ma => mb => () => Promise.race([ma(), mb()]);

export const attemptAsyncio = ma => () => ma()
  .then(a => ({ tag: "Right", value: a }))
  .catch(e => ({ tag: "Left", value: String(e) }));

export const throwErrorAsyncio = msg => () => Promise.reject(new Error(msg));

export const catchErrorAsyncio = ma => handler => () => ma().catch(e => handler(String(e))());

export const bracketAsyncio = acquire => release => use => () =>
  acquire().then(resource =>
    use(resource)()
      .finally(() => release(resource)())
  );

export const liftEffectAsyncio = eff => () => Promise.resolve(eff());
