# Effect values are zero-argument callables, so `nowNs` must BE one.
import sys as _sys
import time as _time

nowNs = lambda: float(_time.perf_counter_ns())

# print() writes through Python's own buffer; when stdout is a pipe that
# buffer is block-sized, so a long shape yields nothing until it ends.
flushOut = lambda: _sys.stdout.flush()


def ffiInc(x):
    return x + 1


def ffiSumArray(xs):
    return sum(xs)
