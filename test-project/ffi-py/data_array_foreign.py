# FFI for Data.Array
# Note: These functions use uncurried signatures to match the JS FFI

__all__ = [
    'rangeImpl', 'replicateImpl', 'fromFoldableImpl', 'length',
    'unconsImpl', 'indexImpl', 'findMapImpl', 'findIndexImpl',
    'findLastIndexImpl', '_insertAt', '_deleteAt', '_updateAt',
    'reverse', 'concat', 'filterImpl', 'partitionImpl',
    'scanlImpl', 'scanrImpl', 'sortByImpl', 'sliceImpl',
    'zipWithImpl', 'anyImpl', 'allImpl', 'unsafeIndexImpl'
]

def rangeImpl(start, end):
    if start > end:
        return list(range(start, end - 1, -1))
    return list(range(start, end + 1))

def replicateImpl(count, value):
    if count < 1:
        return []
    return [value] * count

def fromFoldableImpl(foldr, xs):
    class Cons:
        def __init__(self, head, tail):
            self.head = head
            self.tail = tail
    empty_list = object()
    def curry_cons(head):
        return lambda tail: Cons(head, tail)
    def list_to_array(lst):
        result = []
        while lst is not empty_list:
            result.append(lst.head)
            lst = lst.tail
        return result
    return list_to_array(foldr(curry_cons)(empty_list)(xs))

def length(xs):
    return len(xs)

def unconsImpl(empty, next_, xs):
    if len(xs) == 0:
        return empty({})
    return next_(xs[0])(xs[1:])

def indexImpl(just, nothing, xs, i):
    if i < 0 or i >= len(xs):
        return nothing
    return just(xs[i])

def findMapImpl(nothing, isJust, f, xs):
    for x in xs:
        result = f(x)
        if isJust(result):
            return result
    return nothing

def findIndexImpl(just, nothing, f, xs):
    for i, x in enumerate(xs):
        if f(x):
            return just(i)
    return nothing

def findLastIndexImpl(just, nothing, f, xs):
    for i in range(len(xs) - 1, -1, -1):
        if f(xs[i]):
            return just(i)
    return nothing

def _insertAt(just, nothing, i, a, l):
    if i < 0 or i > len(l):
        return nothing
    return just(l[:i] + [a] + l[i:])

def _deleteAt(just, nothing, i, l):
    if i < 0 or i >= len(l):
        return nothing
    return just(l[:i] + l[i+1:])

def _updateAt(just, nothing, i, a, l):
    if i < 0 or i >= len(l):
        return nothing
    return just(l[:i] + [a] + l[i+1:])

def reverse(l):
    return l[::-1]

def concat(xss):
    result = []
    for xs in xss:
        result.extend(xs)
    return result

def filterImpl(f, xs):
    return [x for x in xs if f(x)]

def partitionImpl(f, xs):
    yes, no = [], []
    for x in xs:
        if f(x):
            yes.append(x)
        else:
            no.append(x)
    return {'yes': yes, 'no': no}

def scanlImpl(f, b, xs):
    acc = b
    out = []
    for x in xs:
        acc = f(acc)(x)
        out.append(acc)
    return out

def scanrImpl(f, b, xs):
    acc = b
    out = [None] * len(xs)
    for i in range(len(xs) - 1, -1, -1):
        acc = f(xs[i])(acc)
        out[i] = acc
    return out

def sortByImpl(compare, fromOrdering, xs):
    if len(xs) < 2:
        return xs[:]
    out = xs[:]
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
    merge_from_to(out, xs[:], 0, len(xs))
    return out

def sliceImpl(s, e, l):
    return l[s:e]

def zipWithImpl(f, xs, ys):
    l = min(len(xs), len(ys))
    return [f(xs[i])(ys[i]) for i in range(l)]

def anyImpl(p, xs):
    for x in xs:
        if p(x):
            return True
    return False

def allImpl(p, xs):
    for x in xs:
        if not p(x):
            return False
    return True

def unsafeIndexImpl(xs, n):
    return xs[n]
