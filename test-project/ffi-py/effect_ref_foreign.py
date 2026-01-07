# FFI for Effect.Ref
__all__ = ['_new', 'read', 'modifyImpl', 'write']

def _new(val):
    return lambda: [val]

def read(ref):
    return lambda: ref[0]

def modifyImpl(f):
    def step(ref):
        def effect():
            result = f(ref[0])
            ref[0] = result['state']
            return result['value']
        return effect
    return step

def write(val):
    def step(ref):
        def effect():
            ref[0] = val
            return None
        return effect
    return step
