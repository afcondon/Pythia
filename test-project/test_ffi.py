#!/usr/bin/env python3
"""
FFI Test Harness for PureScript Python Backend

This script tests all Python FFI implementations to ensure they work correctly.
Run from the test-project directory:
    python3 test_ffi.py
"""

import sys
import os
import traceback

# Add output-py-new to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'output-py-new'))

class TestResults:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.errors = []

    def ok(self, name):
        self.passed += 1
        print(f"  ✓ {name}")

    def fail(self, name, error):
        self.failed += 1
        self.errors.append((name, error))
        print(f"  ✗ {name}: {error}")

    def summary(self):
        print(f"\n{'='*60}")
        print(f"Results: {self.passed} passed, {self.failed} failed")
        if self.errors:
            print("\nFailed tests:")
            for name, error in self.errors:
                print(f"  - {name}: {error}")
        return self.failed == 0


def test_effect(results):
    """Test Effect FFI"""
    print("\n[Effect]")
    try:
        import effect_foreign as E

        # pureE
        eff = E.pureE(42)
        assert eff() == 42
        results.ok("pureE")

        # bindE
        double_eff = E.bindE(E.pureE(21))(lambda x: E.pureE(x * 2))
        assert double_eff() == 42
        results.ok("bindE")

        # forE
        counter = [0]
        def incr(i):
            def effect():
                counter[0] += i
            return effect
        E.forE(1)(5)(incr)()
        assert counter[0] == 1+2+3+4  # 10
        results.ok("forE")

    except Exception as e:
        results.fail("Effect", str(e))


def test_console(results):
    """Test Effect.Console FFI"""
    print("\n[Effect.Console]")
    try:
        import effect_console_foreign as C

        # Just test it doesn't crash
        C.log("test message")()
        results.ok("log")

        C.warn("test warning")()
        results.ok("warn")

    except Exception as e:
        results.fail("Effect.Console", str(e))


def test_ref(results):
    """Test Effect.Ref FFI"""
    print("\n[Effect.Ref]")
    try:
        import effect_ref_foreign as R

        # new and read
        ref = R._new(10)()
        assert R.read(ref)() == 10
        results.ok("new + read")

        # write
        R.write(20)(ref)()
        assert R.read(ref)() == 20
        results.ok("write")

        # modifyImpl - takes a function that returns {state: newState, value: returnValue}
        def modify_fn(x):
            return {'state': x + 5, 'value': x}  # returns old value, sets new state
        old_val = R.modifyImpl(modify_fn)(ref)()
        assert old_val == 20  # returned old value
        assert R.read(ref)() == 25  # new state
        results.ok("modifyImpl")

    except Exception as e:
        results.fail("Effect.Ref", str(e))


def test_array(results):
    """Test Data.Array FFI"""
    print("\n[Data.Array]")
    try:
        import data_array_foreign as A

        just = lambda x: ("Just", x)
        nothing = ("Nothing",)

        # rangeImpl (uncurried, inclusive of end)
        assert A.rangeImpl(1, 5) == [1, 2, 3, 4, 5]  # inclusive
        assert A.rangeImpl(5, 1) == [5, 4, 3, 2, 1]  # descending
        results.ok("rangeImpl")

        # length
        assert A.length([1, 2, 3]) == 3
        results.ok("length")

        # unconsImpl (uncurried)
        empty_fn = lambda _: ("Nothing",)
        next_fn = lambda x: lambda xs: ("Just", {"head": x, "tail": xs})
        assert A.unconsImpl(empty_fn, next_fn, [])[0] == "Nothing"
        result = A.unconsImpl(empty_fn, next_fn, [1, 2, 3])
        assert result[0] == "Just"
        assert result[1]["head"] == 1
        assert result[1]["tail"] == [2, 3]
        results.ok("unconsImpl")

        # indexImpl (uncurried)
        assert A.indexImpl(just, nothing, [10, 20, 30], 1) == ("Just", 20)
        assert A.indexImpl(just, nothing, [10, 20, 30], 10) == ("Nothing",)
        results.ok("indexImpl")

        # filterImpl (uncurried)
        assert A.filterImpl(lambda x: x > 2, [1, 2, 3, 4]) == [3, 4]
        results.ok("filterImpl")

        # zipWithImpl (uncurried)
        assert A.zipWithImpl(lambda x: lambda y: x + y, [1, 2], [10, 20]) == [11, 22]
        results.ok("zipWithImpl")

    except Exception as e:
        results.fail("Data.Array", str(e))


def test_eq(results):
    """Test Data.Eq FFI"""
    print("\n[Data.Eq]")
    try:
        import data_eq_foreign as E

        assert E.eqBooleanImpl(True)(True) == True
        assert E.eqBooleanImpl(True)(False) == False
        results.ok("eqBooleanImpl")

        assert E.eqIntImpl(42)(42) == True
        assert E.eqIntImpl(42)(43) == False
        results.ok("eqIntImpl")

        assert E.eqStringImpl("hello")("hello") == True
        assert E.eqStringImpl("hello")("world") == False
        results.ok("eqStringImpl")

    except Exception as e:
        results.fail("Data.Eq", str(e))


def test_ord(results):
    """Test Data.Ord FFI"""
    print("\n[Data.Ord]")
    try:
        import data_ord_foreign as O

        lt, eq, gt = -1, 0, 1
        assert O.ordIntImpl(lt)(eq)(gt)(1)(2) == lt
        assert O.ordIntImpl(lt)(eq)(gt)(2)(2) == eq
        assert O.ordIntImpl(lt)(eq)(gt)(3)(2) == gt
        results.ok("ordIntImpl")

    except Exception as e:
        results.fail("Data.Ord", str(e))


def test_show(results):
    """Test Data.Show FFI"""
    print("\n[Data.Show]")
    try:
        import data_show_foreign as S

        assert S.showIntImpl(42) == "42"
        results.ok("showIntImpl")

        assert S.showNumberImpl(3.14) == "3.14"
        results.ok("showNumberImpl")

        # Python repr uses single quotes: 'hello'
        result = S.showStringImpl("hello")
        assert result in ["'hello'", '"hello"']  # Accept either quote style
        results.ok("showStringImpl")

        # Test showArrayImpl
        arr_shower = S.showArrayImpl(str)
        assert arr_shower([1, 2, 3]) == "[1, 2, 3]"
        results.ok("showArrayImpl")

    except Exception as e:
        results.fail("Data.Show", str(e))


def test_partial(results):
    """Test Partial FFI"""
    print("\n[Partial]")
    try:
        import partial_foreign as P

        try:
            P._crashWith("test crash")
            results.fail("_crashWith", "should have thrown")
        except Exception as e:
            assert "test crash" in str(e)
            results.ok("_crashWith")

    except Exception as e:
        results.fail("Partial", str(e))


def test_control_extend(results):
    """Test Control.Extend FFI"""
    print("\n[Control.Extend]")
    try:
        import control_extend_foreign as E

        # arrayExtend applies f to each suffix
        arr = [1, 2, 3]
        extended = E.arrayExtend(sum)(arr)
        assert extended == [6, 5, 3]  # sum([1,2,3]), sum([2,3]), sum([3])
        results.ok("arrayExtend")

    except Exception as e:
        results.fail("Control.Extend", str(e))


def test_array_nonempty(results):
    """Test Data.Array.NonEmpty.Internal FFI"""
    print("\n[Data.Array.NonEmpty.Internal]")
    try:
        import data_array_non_empty_internal_foreign as N

        # foldl1Impl
        result = N.foldl1Impl(lambda acc: lambda x: acc + x, [1, 2, 3, 4])
        assert result == 10
        results.ok("foldl1Impl")

        # foldr1Impl
        result = N.foldr1Impl(lambda x: lambda acc: x - acc, [1, 2, 3])
        assert result == 2  # 1 - (2 - 3) = 1 - (-1) = 2
        results.ok("foldr1Impl")

    except Exception as e:
        results.fail("Data.Array.NonEmpty.Internal", str(e))


def test_st_uncurried(results):
    """Test Control.Monad.ST.Uncurried FFI"""
    print("\n[Control.Monad.ST.Uncurried]")
    try:
        import control_monad_s_t_uncurried_foreign as U

        # mkSTFn2 and runSTFn2
        def curried_add(a):
            return lambda b: lambda: a + b

        uncurried = U.mkSTFn2(curried_add)
        assert uncurried(2, 3) == 5
        results.ok("mkSTFn2")

        def uncurried_mul(a, b):
            return a * b

        curried_st = U.runSTFn2(uncurried_mul)
        assert curried_st(3)(4)() == 12
        results.ok("runSTFn2")

    except Exception as e:
        results.fail("Control.Monad.ST.Uncurried", str(e))


def test_asyncio(results):
    """Test Control.Monad.Asyncio FFI"""
    print("\n[Control.Monad.Asyncio]")
    try:
        import control_monad_asyncio_foreign as A

        # pure and run
        result = A.runAsyncio(A.pureAsyncio(42))()
        assert result == 42
        results.ok("pureAsyncio + runAsyncio")

        # map
        result = A.runAsyncio(A.mapAsyncio(lambda x: x * 2)(A.pureAsyncio(21)))()
        assert result == 42
        results.ok("mapAsyncio")

        # bind
        result = A.runAsyncio(A.bindAsyncio(A.pureAsyncio(21))(lambda x: A.pureAsyncio(x * 2)))()
        assert result == 42
        results.ok("bindAsyncio")

        # attempt success
        result = A.runAsyncio(A.attemptAsyncio(A.pureAsyncio(42)))()
        assert result == ("Right", 42)
        results.ok("attemptAsyncio (success)")

        # attempt error
        result = A.runAsyncio(A.attemptAsyncio(A.throwErrorAsyncio("oops")))()
        assert result[0] == "Left"
        results.ok("attemptAsyncio (error)")

    except Exception as e:
        results.fail("Control.Monad.Asyncio", str(e))


def test_assert(results):
    """Test Test.Assert FFI"""
    print("\n[Test.Assert]")
    try:
        import test_assert_foreign as T

        # assertImpl - pass
        T.assertImpl("should pass")(True)()
        results.ok("assertImpl (pass)")

        # assertImpl - fail
        try:
            T.assertImpl("expected failure")(False)()
            results.fail("assertImpl (fail)", "should have thrown")
        except AssertionError:
            results.ok("assertImpl (fail)")

        # checkThrows - throws
        def throws(u):
            raise ValueError("test")
        assert T.checkThrows(throws)() == True
        results.ok("checkThrows (throws)")

        # checkThrows - no throw
        def no_throw(u):
            return 42
        assert T.checkThrows(no_throw)() == False
        results.ok("checkThrows (no throw)")

    except Exception as e:
        results.fail("Test.Assert", str(e))


def test_int(results):
    """Test Data.Int FFI"""
    print("\n[Data.Int]")
    try:
        import data_int_foreign as I

        just = lambda x: ("Just", x)
        nothing = ("Nothing",)

        # fromNumberImpl
        assert I.fromNumberImpl(just)(nothing)(42.0) == ("Just", 42)
        assert I.fromNumberImpl(just)(nothing)(3.14) == ("Nothing",)
        results.ok("fromNumberImpl")

        # toNumber
        assert I.toNumber(42) == 42.0
        results.ok("toNumber")

        # toStringAs
        assert I.toStringAs(10)(42) == "42"
        assert I.toStringAs(16)(255) == "ff"
        assert I.toStringAs(2)(5) == "101"
        results.ok("toStringAs")

        # quot and rem
        assert I.quot(7)(3) == 2
        assert I.quot(-7)(3) == -2
        results.ok("quot")

        assert I.rem(7)(3) == 1
        results.ok("rem")

    except Exception as e:
        results.fail("Data.Int", str(e))


def test_number(results):
    """Test Data.Number FFI"""
    print("\n[Data.Number]")
    try:
        import data_number_foreign as N
        import math

        # Constants
        assert math.isnan(N.nan)
        assert N.infinity == float('inf')
        results.ok("constants")

        # Predicates
        assert N.isNaN(float('nan')) == True
        assert N.isFinite(42.0) == True
        assert N.isFinite(float('inf')) == False
        results.ok("predicates")

        # Math functions (now shadowing builtins)
        assert N.abs(-5) == 5
        assert N.floor(3.7) == 3
        assert N.ceil(3.2) == 4
        results.ok("basic math")

        # Curried functions (now shadowing builtins)
        assert N.max(3)(5) == 5
        assert N.min(3)(5) == 3
        assert N.pow(2)(3) == 8
        results.ok("curried math")

        # sign and trunc
        assert N.sign(5) == 1.0
        assert N.sign(-5) == -1.0
        assert N.sign(0) == 0.0
        assert N.trunc(3.7) == 3
        assert N.trunc(-3.7) == -3
        results.ok("sign and trunc")

    except Exception as e:
        results.fail("Data.Number", str(e))


def test_string_common(results):
    """Test Data.String.Common FFI"""
    print("\n[Data.String.Common]")
    try:
        import data_string_common_foreign as S

        # replace
        assert S.replace("foo")("bar")("foo baz foo") == "bar baz foo"
        results.ok("replace")

        # replaceAll
        assert S.replaceAll("foo")("bar")("foo baz foo") == "bar baz bar"
        results.ok("replaceAll")

        # split
        assert S.split(",")("a,b,c") == ["a", "b", "c"]
        results.ok("split")

        # case conversion
        assert S.toLower("HELLO") == "hello"
        assert S.toUpper("hello") == "HELLO"
        results.ok("case conversion")

        # trim
        assert S.trim("  hello  ") == "hello"
        results.ok("trim")

        # joinWith
        assert S.joinWith(", ")(["a", "b", "c"]) == "a, b, c"
        results.ok("joinWith")

    except Exception as e:
        results.fail("Data.String.Common", str(e))


def test_string_code_units(results):
    """Test Data.String.CodeUnits FFI"""
    print("\n[Data.String.CodeUnits]")
    try:
        import data_string_code_units_foreign as S

        # fromCharArray / toCharArray
        assert S.fromCharArray(['h', 'i']) == "hi"
        assert S.toCharArray("hi") == ['h', 'i']
        results.ok("char array conversion")

        # length
        assert S.length("hello") == 5
        results.ok("length")

        just = lambda x: ("Just", x)
        nothing = ("Nothing",)

        # _charAt
        assert S._charAt(just)(nothing)(0)("hello") == ("Just", "h")
        assert S._charAt(just)(nothing)(10)("hello") == ("Nothing",)
        results.ok("_charAt")

        # _indexOf
        assert S._indexOf(just)(nothing)("ll")("hello") == ("Just", 2)
        assert S._indexOf(just)(nothing)("x")("hello") == ("Nothing",)
        results.ok("_indexOf")

        # take / drop
        assert S.take(3)("hello") == "hel"
        assert S.drop(3)("hello") == "lo"
        results.ok("take/drop")

        # splitAt
        result = S.splitAt(3)("hello")
        assert result['before'] == "hel"
        assert result['after'] == "lo"
        results.ok("splitAt")

    except Exception as e:
        results.fail("Data.String.CodeUnits", str(e))


def test_lazy(results):
    """Test Data.Lazy FFI"""
    print("\n[Data.Lazy]")
    try:
        import data_lazy_foreign as L

        # Test memoization
        call_count = [0]
        def expensive():
            call_count[0] += 1
            return 42

        lazy = L.defer(expensive)
        assert call_count[0] == 0  # Not called yet
        results.ok("defer (no evaluation)")

        result1 = L.force(lazy)
        assert result1 == 42
        assert call_count[0] == 1
        results.ok("force (first call)")

        result2 = L.force(lazy)
        assert result2 == 42
        assert call_count[0] == 1  # Still 1, memoized
        results.ok("force (memoized)")

    except Exception as e:
        results.fail("Data.Lazy", str(e))


def test_exception(results):
    """Test Effect.Exception FFI"""
    print("\n[Effect.Exception]")
    try:
        import effect_exception_foreign as E

        # error creation
        err = E.error("test error")
        assert E.message(err) == "test error"
        assert E.name(err) == "Error"
        results.ok("error + message + name")

        # throwException and catchException
        def throw_action():
            return E.throwException(E.error("oops"))()

        def handler(e):
            return lambda: "caught: " + E.message(e)

        result = E.catchException(handler)(throw_action)()
        assert result == "caught: oops"
        results.ok("throwException + catchException")

    except Exception as e:
        results.fail("Effect.Exception", str(e))


def test_int_bits(results):
    """Test Data.Int.Bits FFI"""
    print("\n[Data.Int.Bits]")
    try:
        import data_int_bits_foreign as B

        # and
        assert B.and_(5)(3) == 1  # 101 & 011 = 001
        results.ok("and_")

        # or
        assert B.or_(5)(3) == 7  # 101 | 011 = 111
        results.ok("or_")

        # xor
        assert B.xor(5)(3) == 6  # 101 ^ 011 = 110
        results.ok("xor")

        # shl (left shift)
        assert B.shl(1)(4) == 16  # 1 << 4 = 16
        results.ok("shl")

        # shr (arithmetic right shift)
        assert B.shr(16)(2) == 4  # 16 >> 2 = 4
        assert B.shr(-16)(2) == -4  # sign-extending
        results.ok("shr")

        # zshr (logical right shift, zero-filling)
        assert B.zshr(16)(2) == 4
        results.ok("zshr")

        # complement
        assert B.complement(0) == -1
        results.ok("complement")

    except Exception as e:
        results.fail("Data.Int.Bits", str(e))


def test_enum(results):
    """Test Data.Enum FFI"""
    print("\n[Data.Enum]")
    try:
        import data_enum_foreign as E

        # toCharCode
        assert E.toCharCode('A') == 65
        assert E.toCharCode('a') == 97
        results.ok("toCharCode")

        # fromCharCode
        assert E.fromCharCode(65) == 'A'
        assert E.fromCharCode(97) == 'a'
        results.ok("fromCharCode")

    except Exception as e:
        results.fail("Data.Enum", str(e))


def test_string_code_points(results):
    """Test Data.String.CodePoints FFI"""
    print("\n[Data.String.CodePoints]")
    try:
        import data_string_code_points_foreign as S

        just = lambda x: ("Just", x)
        nothing = ("Nothing",)

        # _unsafeCodePointAt0
        getter = S._unsafeCodePointAt0(None)  # fallback not needed in Python
        assert getter("A") == 65
        assert getter("😀") == 128512  # emoji
        results.ok("_unsafeCodePointAt0")

        # _singleton
        singleton = S._singleton(None)  # fallback not needed
        assert singleton(65) == 'A'
        assert singleton(128512) == '😀'
        results.ok("_singleton")

        # _fromCodePointArray
        from_array = S._fromCodePointArray(chr)
        assert from_array([72, 105]) == "Hi"
        results.ok("_fromCodePointArray")

        # _toCodePointArray
        to_array = S._toCodePointArray(None)(ord)
        assert to_array("Hi") == [72, 105]
        results.ok("_toCodePointArray")

        # _take
        take = S._take(None)
        assert take(2)("Hello") == "He"
        assert take(2)("😀🎉") == "😀🎉"  # 2 code points
        results.ok("_take")

        # _countPrefix
        count = S._countPrefix(None)(ord)
        # Count prefix of lowercase 'a' characters
        assert count(lambda cp: cp == ord('a'))("aaab") == 3
        assert count(lambda cp: cp == ord('a'))("baaa") == 0  # first char isn't 'a'
        assert count(lambda cp: True)("hello") == 5  # all match
        results.ok("_countPrefix")

    except Exception as e:
        results.fail("Data.String.CodePoints", str(e))


def test_array_st(results):
    """Test Data.Array.ST FFI"""
    print("\n[Data.Array.ST]")
    try:
        import data_array_s_t_foreign as ST

        just = lambda x: ("Just", x)
        nothing = ("Nothing",)

        # new
        arr = ST.new()
        assert arr == []
        results.ok("new")

        # pushAllImpl
        arr = []
        new_len = ST.pushAllImpl([1, 2, 3], arr)
        assert new_len == 3
        assert arr == [1, 2, 3]
        results.ok("pushAllImpl")

        # pushImpl
        arr = [1, 2]
        new_len = ST.pushImpl(3, arr)
        assert new_len == 3
        assert arr == [1, 2, 3]
        results.ok("pushImpl")

        # peekImpl
        arr = [10, 20, 30]
        assert ST.peekImpl(just, nothing, 1, arr) == ("Just", 20)
        assert ST.peekImpl(just, nothing, 10, arr) == ("Nothing",)
        results.ok("peekImpl")

        # pokeImpl
        arr = [1, 2, 3]
        assert ST.pokeImpl(1, 99, arr) == True
        assert arr == [1, 99, 3]
        assert ST.pokeImpl(10, 99, arr) == False
        results.ok("pokeImpl")

        # popImpl
        arr = [1, 2, 3]
        assert ST.popImpl(just, nothing, arr) == ("Just", 3)
        assert arr == [1, 2]
        assert ST.popImpl(just, nothing, []) == ("Nothing",)
        results.ok("popImpl")

        # shiftImpl
        arr = [1, 2, 3]
        assert ST.shiftImpl(just, nothing, arr) == ("Just", 1)
        assert arr == [2, 3]
        results.ok("shiftImpl")

        # unshiftAllImpl
        arr = [3, 4]
        new_len = ST.unshiftAllImpl([1, 2], arr)
        assert arr == [1, 2, 3, 4]
        results.ok("unshiftAllImpl")

        # spliceImpl
        arr = [1, 2, 3, 4, 5]
        removed = ST.spliceImpl(1, 2, [10, 20], arr)
        assert removed == [2, 3]
        assert arr == [1, 10, 20, 4, 5]
        results.ok("spliceImpl")

        # freezeImpl / thawImpl
        arr = [1, 2, 3]
        frozen = ST.freezeImpl(arr)
        arr[0] = 99
        assert frozen == [1, 2, 3]  # original unchanged
        results.ok("freezeImpl")

        # lengthImpl
        assert ST.lengthImpl([1, 2, 3]) == 3
        results.ok("lengthImpl")

    except Exception as e:
        results.fail("Data.Array.ST", str(e))


def main():
    print("="*60)
    print("PureScript Python Backend - FFI Test Suite")
    print("="*60)

    results = TestResults()

    # Core modules
    test_effect(results)
    test_console(results)
    test_ref(results)
    test_array(results)
    test_eq(results)
    test_ord(results)
    test_show(results)
    test_partial(results)

    # Recently added
    test_control_extend(results)
    test_array_nonempty(results)
    test_st_uncurried(results)
    test_asyncio(results)
    test_assert(results)

    # Priority 2 packages
    test_int(results)
    test_number(results)
    test_string_common(results)
    test_string_code_units(results)
    test_lazy(results)
    test_exception(results)

    # Additional FFI modules
    test_int_bits(results)
    test_enum(results)
    test_string_code_points(results)
    test_array_st(results)

    success = results.summary()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
