# FFI for Data.Show
def showIntImpl(n):
    return str(n)

def showNumberImpl(n):
    return str(n)

def showCharImpl(c):
    return repr(c)

def showStringImpl(s):
    # Use double quotes to match JS semantics
    import json
    return json.dumps(s)

def showArrayImpl(f):
    return lambda xs: '[' + ','.join(f(x) for x in xs) + ']'
