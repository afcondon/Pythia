# The seam-tax lane (Pythia)

**What does it cost to reach a real Python library from PureScript, versus
reaching it from a plain Python program?**

```bash
python3 run_seam.py                 # build both arms, run, compare
python3 run_seam.py --skip-build
python3 run_seam.py --json
```

Companion to `purescript-julia/perf-seam`. `src/Seam/` is **byte-identical**
between the two, as the canary's shapes and the differential corpus are; only
`ffi-py/`, the native arm and the calibrated ladder differ. The physics is the
same CR3BP problem, so the two runtimes land on one scale — the library differs
because the ecosystems differ (`scipy.integrate.solve_ivp` with DOP853 and
terminal events, against Julia's `OrdinaryDiffEq` with Vern9), and that is the
honest comparison, since the point is reaching each runtime's OWN library.

See the Jurist README for the full design rationale. In brief: PureScript owns
the loop and calls the library once per orbit; `native/seam_native.py` runs the
identical loop over the identical 400 orbits; checksums gate before any timing
is read.

## Why the ladder differs from Jurist's

The axis under test is **microseconds of library work bought per crossing**;
the horizon is only the dial. One 150-period solve costs ~10 ms through
OrdinaryDiffEq and **~497 ms through scipy** — a factor of fifty, because
scipy's DOP853 calls the right-hand side through a Python callback while Julia
specialises it to native code. So each backend supplies its own ladder from its
FFI (`Seam.Kernel.workLadder`), calibrated to span the same microsecond range.
Reusing Julia's numbers here would have taken about fifty minutes and measured
a range that did not overlap Julia's at all.

That fifty-fold difference is not what this lane is measuring and should not be
read as one. It is a property of the two *libraries*, not of the two seams.

## Results — 2026-08-02, M4 MBP, CPython 3.11, scipy 1.18, numpy 2.4

### Work per call: practical

```
  work/call     poly      native    tax    distort   crossing
  us            ms        ms                         us/call
  ---------------------------------------------------------
       281      116.2     112.8    1.03     1.01       7.0
       494      204.0     198.1    1.03     1.01       8.4
      1032      415.5     413.4    1.01     0.99      10.0
      3146     1264.9    1259.4    1.00     1.00      15.9
      8790     3511.1    3517.8    1.00     1.00      22.1
```

**Across a 60× range the tax stayed within 1.00–1.03×**, and structural
distortion never exceeded 1.01 — the seam is not deforming *how* scipy gets
called. Fit: `crossing ≈ 8.0 us + 0.17 % of the library call`.

### Payload per call: this is where the runtimes diverge

```
  samples returned   poly      native    tax    crossing
                     ms        ms               us/call
  ------------------------------------------------------
      1 (2 Numbers)   441.4     439.8   1.00      14.7
     16 (32)          596.4     587.6   1.01      18.2
    128 (256)         646.6     624.7   1.04      42.6
   1024 (2048)        842.9     751.7   1.12     227.9
```

Fitted over the payload axis:

| | per `Number` READ | folding 1,000 |
|---|---:|---:|
| **Jurist** (purejl) | ~1.9 ns | ~2 µs |
| **Pythia** (purepy) | **~104 ns** | **~104 µs** |

**Reading an `Array Number` costs purepy roughly 53× what it costs purejl.**
Structural rather than a defect: on Julia it is a contiguous `Vector{Float64}`
folded by native code, on Python a list of boxed floats walked by generated
code.

**It is the READ, not the crossing.** `Seam.ArrayCost` separates them by
running the same call twice — once taking only `Array.length`, once folding
every element — and gets 4,402 µs against 6,090 µs over 16,384 Numbers, i.e.
103 ns for the fold and nothing for the transport. On purepy an `Array Number`
*is* the Python list the foreign returned, so handing it across copies nothing:

```bash
.venv/bin/python -c "import sys; sys.path.insert(0,'output-py'); \
    import Seam_ArrayCost; Seam_ArrayCost.main()"
```

This is the number that explains Grid Explorer. That exhibit measured **44.7 %
seam cost** before its payload was narrowed and 8.1 % after, and it was
marshalling ~1,000 records per solve against ~18 ms of `runpp`. At ~104 ns per
field crossed, ~1,000 records of a dozen fields each is ~1.2 ms per solve —
which is the observed cost, arrived at independently.

## The verdict, and it is conditional

**Practical, with one design rule attached.** Reaching Python's library
ecosystem from PureScript costs 1–3 % at any realistic *call* granularity, and
the boundary itself is ~8 µs. But the return payload is not free the way it is
on Julia, so:

> On Pythia, don't make PureScript ITERATE a big foreign array. Passing one
> onward costs nothing; folding it costs ~100 ns an element. A seam that hands
> back a whole result set the core then walks pays for every field; one that
> hands back the four scalars the caller reads does not.

Both halves of that were learned the expensive way in Grid Explorer before this
lane existed to price them.

## The lane's first find was a correctness bug, not a timing

The checksum gate refused to report anything on the first run, because
purepy's `show` was silently corrupting every `Number` that came back from
scipy:

```
show (399.7569 :: Number)   -- from numpy  ->  "np.float64(3997569)"
show (1.0      :: Number)   -- from numpy  ->  "np.float64(10)"
```

`_js_number_string` did `repr(n)` and then stripped `.` out of the mantissa for
JS-style digit placement; numpy 2.x changed scalar `repr` from `399.7569` to
`np.float64(399.7569)`, so the parser mangled it. No exception — just wrong
numbers, in any purepy program that shows a value it got back from
numpy/scipy/pandas. Fixed by coercing `float(n)` first.

Nothing else would have caught it. **The differential corpus only tests values
PureScript itself constructed**; values that *enter* from a foreign library are
a separate population that nothing exercises, because the corpus deliberately
contains no foreign libraries. A perf lane with a checksum gate turned out to
be a correctness instrument.

### …so the lane now gates on that population deliberately

`src/Seam/ForeignOrigin.purs` — byte-identical with the Jurist lane's copy,
like the rest of `Seam/` — runs before any timing and holds the property the
bug violated:

```
show x == show (widen x)      for every x, however x arrived
```

The rendering of a `Number` may depend on its **value** and must not depend on
its **representation**. `asRepresentation` manufactures the fiction every FFI
signature creates, handing back `float`, `numpy.float64`, `numpy.float32`,
`Decimal` and `int` all typed as `Number`. It deliberately does not bind scipy:
pinning the regression test to a library would make it track that library's
release notes, and the hazard needs only the type promise.

```bash
.venv/bin/python -c "import sys; sys.path.insert(0,'output-py'); \
    import Seam_ForeignOrigin; Seam_ForeignOrigin.main()"
```

Patch `n = float(n)` back out of `output-py/_purepy_runtime.py` and it doesn't
merely fail, it raises: `repr(np.float64(1e-7))` is `np.float64(1e-07)` and the
exponent parse dies on `'-07)'`. The pre-fix behaviour was a mixture of silent
wrong digits and a confusing crash, which is what made it hard to attribute.

The same audit found the identical hazard **unfixed in Jurist** — Julia's
`Base.string` renders `Float32`, `Rational` and `BigFloat` each in its own
notation — and found **Gnomon immune by construction**, because psgo's boxed
`any` is unwrapped by a type assertion that panics instead of guessing. Full
write-up in `docs/kb/reference/seam-tax.md`.

## Caveats

- One library, one problem shape. scipy's `solve_ivp` returns a small object;
  a library whose natural return is a large nested structure would exercise
  marshalling harder still.
- `reps = 3`, min-of-reps. Read 1.00× as "indistinguishable", not as exact.
- The `.venv` is a symlink to `examples/grid-explorer/.venv`, which pins the
  scipy and numpy this lane needs.
