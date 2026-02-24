# UTF-16 String Semantics Audit

**Status**: active
**Created**: 2026-02-24
**Purpose**: Document every function in `Data.String.CodeUnits` FFI with Python vs JS behavior analysis.

## Executive Summary

Python strings are sequences of **Unicode code points** (UCS-4 internally in CPython). JavaScript strings are sequences of **UTF-16 code units**. This difference is invisible for characters in the Basic Multilingual Plane (U+0000 to U+FFFF) — which covers ASCII, Latin, Greek, Cyrillic, CJK unified ideographs, and most commonly used characters.

The divergence appears for characters **outside the BMP** (U+10000 and above), which include:
- Emoji (U+1F600–U+1F64F, U+1F900–U+1F9FF, etc.)
- CJK Extension B (U+20000–U+2A6DF)
- Musical symbols (U+1D100–U+1D1FF)
- Historic scripts (Egyptian hieroglyphs, cuneiform, etc.)
- Mathematical alphanumeric symbols (U+1D400–U+1D7FF)

In JavaScript (UTF-16), these characters are represented as **surrogate pairs** — two 16-bit code units. In Python, they are single code points.

---

## Affected Module: `data_string_code_units_foreign.py`

### Function-by-Function Analysis

#### `length(s)` — GET STRING LENGTH

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `len(s)` | `s.length` |
| BMP strings | Correct | Correct |
| `"hello"` | 5 | 5 |
| `"café"` | 4 | 4 |
| `"😀"` | **1** | **2** |
| `"a😀b"` | **3** | **4** |
| `"🇺🇸"` (flag) | **2** | **4** |

**Diverges for non-BMP**: Yes
**Fix**: `len(s.encode('utf-16-le')) // 2`

---

#### `toCharArray(s)` — SPLIT INTO CHARACTER ARRAY

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `list(s)` | `s.split('')` |
| `"hi"` | `['h', 'i']` | `['h', 'i']` |
| `"😀"` | **`['😀']`** | **`['\uD83D', '\uDE00']`** |
| `"a😀b"` | **`['a', '😀', 'b']`** | **`['a', '\uD83D', '\uDE00', 'b']`** |

**Diverges for non-BMP**: Yes
**Fix**: Encode to UTF-16-LE, iterate 2 bytes at a time, decode each pair back to a Python string.

---

#### `fromCharArray(chars)` — JOIN CHARACTER ARRAY

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `''.join(chars)` | `chars.join('')` |

**Diverges**: No — both join whatever characters they're given. The divergence is in what `toCharArray` produces as input.

---

#### `singleton(c)` — CREATE SINGLE-CHAR STRING

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `c` (identity) | `c` |

**Diverges**: No — both return the character as-is.

---

#### `_charAt(just)(nothing)(i)(s)` — GET CHARACTER AT INDEX

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `s[i]` | `s.charAt(i)` |
| `charAt 0 "hello"` | `Just "h"` | `Just "h"` |
| `charAt 0 "😀x"` | **`Just "😀"`** | **`Just "\uD83D"`** |
| `charAt 1 "😀x"` | **`Just "x"`** | **`Just "\uDE00"`** |
| `charAt 2 "😀x"` | **`Nothing`** | **`Just "x"`** |

**Diverges for non-BMP**: Yes — Python indexes by code point, JS by code unit.
**Fix**: Encode to UTF-16-LE, index by code unit position.

---

#### `_toChar(just)(nothing)(s)` — CONVERT SINGLE-CHAR STRING TO CHAR

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `len(s) == 1` check | `s.length === 1` check |
| `_toChar "a"` | `Just 'a'` | `Just 'a'` |
| `_toChar "😀"` | **`Just '😀'`** (len=1) | **`Nothing`** (length=2) |

**Diverges for non-BMP**: Yes — an emoji is one code point (Python) but two code units (JS).
**Fix**: Check `len(s.encode('utf-16-le')) // 2 == 1` instead of `len(s) == 1`.

---

#### `countPrefix(pred)(s)` — COUNT MATCHING PREFIX CHARACTERS

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | Iterate `for c in s` | Iterate by code unit index |
| BMP strings | Correct | Correct |
| Non-BMP | Counts code points | Counts code units |

**Diverges for non-BMP**: Yes — predicates receive different things (full code point vs surrogate half).
**Fix**: Iterate over UTF-16 code units rather than Python characters.

---

#### `_indexOf(just)(nothing)(pattern)(s)` — FIND FIRST INDEX OF PATTERN

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `s.find(pattern)` | `s.indexOf(pattern)` |
| `indexOf "ll" "hello"` | `Just 2` | `Just 2` |
| BMP strings | Returns same index | Returns same index |
| `indexOf "x" "😀x"` | **`Just 1`** | **`Just 2`** |

**Diverges for non-BMP**: Yes — Python returns code point offset, JS returns code unit offset.
**Fix**: After finding with `s.find()`, convert code point index to code unit index.

---

#### `_indexOfStartingAt(just)(nothing)(pattern)(start)(s)` — FIND INDEX FROM POSITION

Same divergence as `_indexOf` — both the `start` parameter and the returned index use code point offsets in Python vs code unit offsets in JS.

**Diverges for non-BMP**: Yes
**Fix**: Convert `start` from code unit to code point offset before calling `s.find()`, then convert result back.

---

#### `_lastIndexOf(just)(nothing)(pattern)(s)` — FIND LAST INDEX

Same divergence pattern as `_indexOf`.

**Diverges for non-BMP**: Yes

---

#### `_lastIndexOfStartingAt(just)(nothing)(pattern)(start)(s)` — FIND LAST INDEX BEFORE POSITION

Same divergence pattern as `_indexOfStartingAt`.

**Diverges for non-BMP**: Yes

---

#### `take(n)(s)` — TAKE FIRST N CHARACTERS

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `s[:n]` | `s.substring(0, n)` |
| `take 3 "hello"` | `"hel"` | `"hel"` |
| `take 1 "😀hello"` | **`"😀"`** | **`"\uD83D"`** (lone surrogate) |
| `take 2 "😀hello"` | **`"😀h"`** | **`"😀"`** |

**Diverges for non-BMP**: Yes
**Fix**: Index into UTF-16 code units, not code points.

---

#### `drop(n)(s)` — DROP FIRST N CHARACTERS

Mirror of `take` — same divergence pattern.

| Aspect | Python | JavaScript |
|--------|--------|------------|
| `drop 1 "😀hello"` | **`"hello"`** | **`"\uDE00hello"`** (lone surrogate + hello) |
| `drop 2 "😀hello"` | **`"ello"`** | **`"hello"`** |

**Diverges for non-BMP**: Yes

---

#### `slice(start)(end)(s)` — EXTRACT SUBSTRING

Combines the issues of `take` and `drop` — both `start` and `end` are code point offsets in Python, code unit offsets in JS.

**Diverges for non-BMP**: Yes

---

#### `splitAt(i)(s)` — SPLIT STRING AT INDEX

| Aspect | Python | JavaScript |
|--------|--------|------------|
| Implementation | `{'before': s[:i], 'after': s[i:]}` | equivalent |
| `splitAt 1 "😀hello"` | **`{before: "😀", after: "hello"}`** | **`{before: "\uD83D", after: "\uDE00hello"}`** |

**Diverges for non-BMP**: Yes

---

## Unaffected Module: `data_string_code_points_foreign.py`

`Data.String.CodePoints` operates on Unicode code points by definition. Python's native string handling **is** code-point-based, so this module is **naturally correct**.

All functions in `data_string_code_points_foreign.py` are correct:
- `_unsafeCodePointAt0` — uses `ord()`, correct
- `_codePointAt` — indexes by code point, correct
- `_countPrefix` — iterates code points, correct
- `_fromCodePointArray` — uses `chr()`, correct
- `_singleton` — uses `chr()`, correct
- `_take` — slices by code point, correct
- `_toCodePointArray` — uses `ord()`, correct

---

## Unaffected Module: `data_string_common_foreign.py`

`Data.String.Common` operates on whole substrings, not individual characters or indices.

| Function | Diverges? | Notes |
|----------|-----------|-------|
| `_localeCompare` | No | Compares whole strings |
| `replace` | No | Finds/replaces whole substrings |
| `replaceAll` | No | Finds/replaces whole substrings |
| `split` | No* | Splits by whole separator |
| `toLower` | No | Case conversion is per-code-point |
| `toUpper` | No | Case conversion is per-code-point |
| `trim` | No | Whitespace stripping |
| `joinWith` | No | Joins whole strings |

*`split` could theoretically diverge if the separator is a lone surrogate, but this is pathological.

---

## Unaffected Module: `data_string_unsafe_foreign.py`

| Function | Diverges? | Notes |
|----------|-----------|-------|
| `charAt` | Yes | Same issue as `_charAt` — indexes by code point |
| `char` | Yes | Same issue as `_toChar` — length check |

---

## Summary Table

| Function | Module | Diverges for non-BMP? | Severity |
|----------|--------|----------------------|----------|
| `length` | CodeUnits | Yes | High — affects all index-based code |
| `toCharArray` | CodeUnits | Yes | High — produces different arrays |
| `fromCharArray` | CodeUnits | No | — |
| `singleton` | CodeUnits | No | — |
| `_charAt` | CodeUnits | Yes | High — wrong character returned |
| `_toChar` | CodeUnits | Yes | Medium — classification differs |
| `countPrefix` | CodeUnits | Yes | Medium |
| `_indexOf` | CodeUnits | Yes | High — wrong index returned |
| `_indexOfStartingAt` | CodeUnits | Yes | High |
| `_lastIndexOf` | CodeUnits | Yes | High |
| `_lastIndexOfStartingAt` | CodeUnits | Yes | High |
| `take` | CodeUnits | Yes | High — wrong substring |
| `drop` | CodeUnits | Yes | High — wrong substring |
| `slice` | CodeUnits | Yes | High |
| `splitAt` | CodeUnits | Yes | High |
| `_unsafeCodePointAt0` | CodePoints | No | — |
| `_codePointAt` | CodePoints | No | — |
| `_countPrefix` | CodePoints | No | — |
| `_fromCodePointArray` | CodePoints | No | — |
| `_singleton` | CodePoints | No | — |
| `_take` | CodePoints | No | — |
| `_toCodePointArray` | CodePoints | No | — |
| All functions | Common | No | — |
| `charAt` | Unsafe | Yes | Same as CodeUnits |
| `char` | Unsafe | Yes | Same as CodeUnits |

---

## Recommendation

### Option 1: Faithful UTF-16 Emulation (Recommended for correctness)

Add UTF-16 helper functions and rewrite `data_string_code_units_foreign.py`:

```python
def _utf16_length(s):
    """Length in UTF-16 code units (matching JS .length)."""
    return len(s.encode('utf-16-le')) // 2

def _utf16_code_units(s):
    """Encode string as list of UTF-16 code unit values."""
    encoded = s.encode('utf-16-le')
    return [int.from_bytes(encoded[i:i+2], 'little') for i in range(0, len(encoded), 2)]

def _codepoint_offset_to_codeunit_offset(s, cp_offset):
    """Convert a code point offset to a UTF-16 code unit offset."""
    prefix = s[:cp_offset]
    return len(prefix.encode('utf-16-le')) // 2

def _codeunit_offset_to_codepoint_offset(s, cu_offset):
    """Convert a UTF-16 code unit offset to a code point offset."""
    encoded = s.encode('utf-16-le')
    # cu_offset code units = cu_offset * 2 bytes
    prefix_bytes = encoded[:cu_offset * 2]
    return len(prefix_bytes.decode('utf-16-le'))

def _utf16_take(n, s):
    """Take first n UTF-16 code units from string."""
    encoded = s.encode('utf-16-le')
    taken = encoded[:n * 2]
    return taken.decode('utf-16-le', errors='surrogatepass')

def _utf16_drop(n, s):
    """Drop first n UTF-16 code units from string."""
    encoded = s.encode('utf-16-le')
    remaining = encoded[n * 2:]
    return remaining.decode('utf-16-le', errors='surrogatepass')

def _utf16_char_at(i, s):
    """Get the UTF-16 code unit at position i as a string."""
    encoded = s.encode('utf-16-le')
    byte_offset = i * 2
    if byte_offset + 2 > len(encoded):
        return None
    unit_bytes = encoded[byte_offset:byte_offset + 2]
    return unit_bytes.decode('utf-16-le', errors='surrogatepass')
```

**Pros**: Correct behavior for all Unicode characters. Cross-backend tests pass.
**Cons**: Performance overhead for every string operation (encode/decode). Adds complexity.

### Option 2: Accept Divergence + Document (Current approach)

Keep current implementation. Document that `Data.String.CodeUnits` diverges for non-BMP characters. Recommend users working with emoji/non-BMP text use `Data.String.CodePoints` instead.

**Pros**: Simple, fast, no maintenance overhead.
**Cons**: Silent bugs for code processing emoji or other non-BMP text.

### Option 3: Hybrid — Fix Critical Functions Only

Fix `length`, `take`, `drop`, `indexOf`, `charAt` (the most commonly used). Leave `countPrefix`, `lastIndexOf`, etc. as-is with documentation.

**Pros**: Fixes the most impactful divergences without full rewrite.
**Cons**: Inconsistent — some functions use code units, others code points.

### Current Decision

**Option 2** (accept divergence + document) for now. Rationale:
- Most PureScript code uses `Data.String.CodePoints` for Unicode-aware operations
- The Python backend targets data science/ML where emoji in strings are less common
- The cross-backend tests explicitly flag these as known divergences
- Fixing can be done incrementally based on user demand

This decision should be revisited if users report bugs related to non-BMP string handling.
