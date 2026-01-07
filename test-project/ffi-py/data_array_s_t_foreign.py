# FFI for Data.Array.ST
# Note: These functions use uncurried signatures to match the JS FFI

__all__ = [
    'new', 'peekImpl', 'pokeImpl', 'lengthImpl', 'popImpl',
    'pushAllImpl', 'pushImpl', 'shiftImpl', 'unshiftAllImpl',
    'spliceImpl', 'unsafeFreezeImpl', 'unsafeThawImpl',
    'freezeImpl', 'thawImpl', 'cloneImpl', 'sortByImpl', 'toAssocArrayImpl'
]

def new():
    return []

def peekImpl(just, nothing, i, xs):
    if 0 <= i < len(xs):
        return just(xs[i])
    return nothing

def pokeImpl(i, a, xs):
    if 0 <= i < len(xs):
        xs[i] = a
        return True
    return False

def lengthImpl(xs):
    return len(xs)

def popImpl(just, nothing, xs):
    if len(xs) > 0:
        return just(xs.pop())
    return nothing

def pushAllImpl(as_, xs):
    xs.extend(as_)
    return len(xs)

def pushImpl(a, xs):
    xs.append(a)
    return len(xs)

def shiftImpl(just, nothing, xs):
    if len(xs) > 0:
        return just(xs.pop(0))
    return nothing

def unshiftAllImpl(as_, xs):
    for i, a in enumerate(as_):
        xs.insert(i, a)
    return len(xs)

def spliceImpl(i, howMany, bs, xs):
    removed = xs[i:i+howMany]
    xs[i:i+howMany] = bs
    return removed

def unsafeFreezeImpl(xs):
    return xs

def unsafeThawImpl(xs):
    return xs

def freezeImpl(xs):
    return list(xs)

def thawImpl(xs):
    return list(xs)

def cloneImpl(xs):
    return list(xs)

def sortByImpl(compare, fromOrdering, xs):
    if len(xs) < 2:
        return xs
    def merge_from_to(xs1, xs2, from_, to):
        mid = from_ + ((to - from_) >> 1)
        if mid - from_ > 1:
            merge_from_to(xs2, xs1, from_, mid)
        if to - mid > 1:
            merge_from_to(xs2, xs1, mid, to)
        i, j, k = from_, mid, from_
        while i < mid and j < to:
            x, y = xs2[i], xs2[j]
            c = fromOrdering(compare(x)(y))
            if c > 0:
                xs1[k] = y
                k += 1
                j += 1
            else:
                xs1[k] = x
                k += 1
                i += 1
        while i < mid:
            xs1[k] = xs2[i]
            k += 1
            i += 1
        while j < to:
            xs1[k] = xs2[j]
            k += 1
            j += 1
    merge_from_to(xs, list(xs), 0, len(xs))
    return xs

def toAssocArrayImpl(xs):
    return [{'value': v, 'index': i} for i, v in enumerate(xs)]
