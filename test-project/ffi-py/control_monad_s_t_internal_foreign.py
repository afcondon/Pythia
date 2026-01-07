# FFI for Control.Monad.ST.Internal

__all__ = [
    'map_', 'pure_', 'bind_', 'run',
    'while_', 'for_', 'foreach',
    'new', 'read', 'modifyImpl', 'write'
]

def map_(f):
    def step(a):
        def effect():
            return f(a())
        return effect
    return step

def pure_(a):
    return lambda: a

def bind_(a):
    def step(f):
        def effect():
            return f(a())()
        return effect
    return step

def run(f):
    return f()

def while_(cond):
    def step(body):
        def effect():
            while cond():
                body()
            return None
        return effect
    return step

def for_(lo):
    def step(hi):
        def step2(f):
            def effect():
                for i in range(lo, hi):
                    f(i)()
                return None
            return effect
        return step2
    return step

def foreach(xs):
    def step(f):
        def effect():
            for x in xs:
                f(x)()
            return None
        return effect
    return step

# STRef operations
def new(val):
    return lambda: [val]

def read(ref):
    return lambda: ref[0]

def modifyImpl(f):
    def step(ref):
        def effect():
            t = f(ref[0])
            ref[0] = t['state']
            return t['value']
        return effect
    return step

def write(val):
    def step(ref):
        def effect():
            ref[0] = val
            return None
        return effect
    return step
