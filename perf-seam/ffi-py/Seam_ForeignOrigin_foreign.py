# Python's alternative representations of "a real number".
#
# This is the lane the bug was actually found in. numpy 1.x rendered
# `repr(numpy.float64(399.7569))` as `399.7569`; numpy 2.x renders it as
# `np.float64(399.7569)`, and the runtime's `_js_number_string` parses `repr`
# and strips '.' out of the mantissa — so `show` printed 3997569 for 399.7569,
# silently, in any purepy program that showed a value it got back from
# numpy/scipy/pandas. Found by a checksum gate in this lane, not by a test;
# this module is the test that would have found it.
#
# Note `str` is NOT affected — numpy 2.x changed `repr` only, which is why
# `showIntImpl`, which does `str(n)`, was never exposed and needs no coercion.
# The audit that established that is in docs/kb/reference/seam-tax.md.
#
# purepy calling convention: curried PureScript arrives as nested unary
# lambdas, and an `Effect` is a zero-argument callable.

import sys as _sys
from decimal import Decimal as _Decimal

import numpy as _np

representations = ["float", "numpy.float64", "numpy.float32", "Decimal", "int"]


def asRepresentation(name):
    def go(n):
        if name == "float":
            return n
        if name == "numpy.float64":
            # Same VALUE as the float — this row isolates the repr change,
            # with no rounding to confuse it with.
            return _np.float64(n)
        if name == "numpy.float32":
            # Different value, and the one a great deal of numpy actually
            # returns: float32 is the default dtype across imaging and ML.
            return _np.float32(n)
        if name == "Decimal":
            # Exact: Decimal(x: float) is the decimal the double denotes, so
            # widening back is lossless.
            return _Decimal(n)
        if name == "int":
            # Lossy on purpose. The invariant is about the value that ARRIVED,
            # and `len`, `.shape`, `argmax` and friends hand back integers
            # where a signature may have promised a Number.
            return round(n)
        raise RuntimeError("Seam.ForeignOrigin: unknown representation " + name)

    return go


def widen(n):
    return float(n)


def exitWith(code):
    return lambda: _sys.exit(code)
