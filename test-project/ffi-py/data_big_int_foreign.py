# FFI for Data.BigInt
# Python integers are arbitrary precision natively, so most operations are trivial.
# BigInt values are represented as plain Python ints.

__all__ = [
    'fromTypeLevelInt', 'fromBaseImpl', 'fromNumberImpl', 'fromInt',
    'toBase', 'toNumber',
    'biAdd', 'biMul', 'biSub', 'biMod', 'biDiv',
    'biEquals', 'biCompare',
    'abs', 'even', 'odd', 'prime', 'pow',
    'not_', 'or_', 'xor', 'and_', 'shl', 'shr',
    'digitsInBase'
]

# --- Constructors ---

def fromTypeLevelInt(s):
    """Convert a type-level integer string to BigInt."""
    return int(s)

def fromBaseImpl(just):
    def go1(nothing):
        def go2(radix):
            def go3(s):
                try:
                    return just(int(s, radix))
                except ValueError:
                    return nothing
            return go3
        return go2
    return go1

def fromNumberImpl(just):
    def go1(nothing):
        def go2(n):
            import math
            if math.isnan(n) or math.isinf(n):
                return nothing
            if n != int(n):
                return nothing
            return just(int(n))
        return go2
    return go1

def fromInt(n):
    """Convert Int to BigInt (identity in Python)."""
    return n

# --- Conversions ---

def toBase(radix):
    def go(n):
        if radix < 2 or radix > 36:
            raise ValueError(f"Invalid radix: {radix}")
        if n == 0:
            return "0"
        digits = "0123456789abcdefghijklmnopqrstuvwxyz"
        negative = n < 0
        n = abs(n)
        result = []
        while n:
            result.append(digits[n % radix])
            n //= radix
        if negative:
            result.append('-')
        return ''.join(reversed(result))
    return go

def toNumber(n):
    """Convert BigInt to Number. May lose precision for large values."""
    return float(n)

# --- Arithmetic ---

def biAdd(x):
    return lambda y: x + y

def biMul(x):
    return lambda y: x * y

def biSub(x):
    return lambda y: x - y

def biMod(x):
    return lambda y: x % y

def biDiv(x):
    return lambda y: x // y

# --- Comparison ---

def biEquals(x):
    return lambda y: x == y

def biCompare(lt):
    def go1(eq):
        def go2(gt):
            def go3(x):
                def go4(y):
                    if x < y:
                        return lt
                    elif x == y:
                        return eq
                    else:
                        return gt
                return go4
            return go3
        return go2
    return go1

# --- Math functions ---

# Note: Python's built-in abs shadows our import, so we define it inline
def abs(n):
    """Absolute value."""
    return n if n >= 0 else -n

def even(n):
    """Check if BigInt is even."""
    return n % 2 == 0

def odd(n):
    """Check if BigInt is odd."""
    return n % 2 != 0

def prime(n):
    """Check if BigInt is prime. Uses simple trial division."""
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    # Trial division up to sqrt(n)
    i = 3
    while i * i <= n:
        if n % i == 0:
            return False
        i += 2
    return True

def pow(base):
    def go(exp):
        return base ** exp
    return go

# --- Bitwise operations ---
# Python handles arbitrary-precision bitwise ops natively

def not_(n):
    """Bitwise NOT. Note: Python's ~ on arbitrary precision may differ from JS BigInt."""
    return ~n

def or_(x):
    return lambda y: x | y

def xor(x):
    return lambda y: x ^ y

def and_(x):
    return lambda y: x & y

def shl(x):
    def go(bits):
        return x << int(bits)
    return go

def shr(x):
    def go(bits):
        return x >> int(bits)
    return go

# --- Digit conversion ---

def digitsInBase(radix):
    def go(n):
        if n == 0:
            return [0]
        negative = n < 0
        n = n if n >= 0 else -n
        digits = []
        while n:
            digits.append(n % radix)
            n //= radix
        digits.reverse()
        return {'value': digits, 'isNegative': negative}
    return go
