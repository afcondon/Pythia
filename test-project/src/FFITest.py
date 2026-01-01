# FFITest foreign implementations for Python
import math

# PureScript functions are curried, so pyAdd takes one argument and returns a function
pyAdd = lambda x: lambda y: x + y

# Similarly for pyMul
pyMul = lambda x: lambda y: x * y

# pySqrt uses Python's math library
pySqrt = lambda x: math.sqrt(x)
