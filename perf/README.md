# The performance canary

The differential suite answers *does this mean the same thing on both
runtimes?* This lane answers the other half: *and does it still cost what it
cost yesterday?*

```bash
cd perf
python3 run_perf.py                    # build, run, check
python3 run_perf.py --skip-build --echo # re-run, streaming
python3 run_perf.py --update-baseline   # re-record (say why in the commit)
```

## What it is for

Until now nothing in this repo would have noticed a code-generator change
that made a common shape ten times slower. The type-nesting finding of
2026-08-01 — a 1,000-iteration `Effect` loop taking 14 seconds — was found by
accident, while writing a test for something else. That is not a process.

The question the lane asks is **"has this backend drifted against itself?"**
Cross-runtime numbers fall out of the table and are printed, but they are not
the claim and should not become the framing. The shapes are chosen to be
*attributable*, not to be representative of real programs, so "Julia is
faster than JavaScript at X" is not a conclusion this lane supports.

## Two axes

The shapes cover both halves of what "performance of PureScript on this
runtime" means:

- **common computational patterns** — counted loops four ways, folds over a
  list and over an array, `map`, string building, record update
- **cost of the FFI seam** — `ffi-call` is `loop-fore` with the increment
  moved to the far side of the boundary, so their difference is the per-call
  crossing cost; `ffi-array` crosses once with n elements, so it measures
  marshalling instead

## Three design decisions worth knowing

**Timing lives in PureScript** (`Bench.Main`), not in the runner. Every
backend therefore executes byte-identical measurement code. A per-backend
harness written in the host language is the obvious alternative and it is
worse: it drifts, and the drift is invisible because it presents as a
performance difference.

**First call and steady state are reported separately.** Conflating them is
what made Jurist's first performance number uninterpretable — "170 ms per
iteration" was 99% compilation. Sizes for a shape run in ascending order
within one process and the first call at each size is timed on its own. That
first call is not a warm-up artefact to be discarded; on Julia a size that
demands types no smaller size demanded compiles again, so *first-call cost
growing with n* is the type-nesting signal itself.

**The baseline stores ratios, not milliseconds.** An absolute baseline is
worthless the moment it leaves the machine that recorded it. Each shape is
normalised, within its own backend and its own run, against `loop-fore` at
n=1000:

| column | meaning |
|---|---|
| `rel` | steady(shape) / steady(calibration) — cost relative to a plain host loop on the same runtime |
| `f/s` | first / steady — how much of the first call is compilation |

Machine speed cancels, so the baseline is portable to CI. `f/s` is the
type-nesting signal in one number: ~1 on a runtime that does not compile per
call site, and large — and *staying* large as n grows — exactly where
specialisation is happening.

## Checksums gate; timings report

Every shape returns an `Int` checksum, and the runner diffs checksums across
backends **before it looks at a single timing**. A benchmark that computes
the wrong answer quickly is the classic way for a performance suite to stay
green while the thing it measures rots.

Drift against the baseline is reported but does not fail the lane yet
(`--gate-drift` turns it into a failure). The tolerance is a loose 2× because
this lane has no variance history: a canary that cries wolf gets muted, which
is strictly worse than one that is slightly deaf. Tighten it once a few weeks
of runs say what the real noise is.

A shape that does not complete is recorded as **DNF** rather than crashing
the lane — see below for why that is a normal outcome here.

## What the first run found (2026-08-01, M4 MBP)

**Pythia has no compilation signal at all.** `f/s` is 1.0 or very near it for
every shape at every size — the whole table, both axes. That is the expected
result and it is worth having on the record rather than assumed: CPython does
not specialise on closure types, so the type-nesting pathology that costs
Jurist 7.1 seconds on a 100-element `foldl` over a `List` costs Pythia
nothing. `fold-list` reads 1.0× at n=10, 25, 50 and 100.

That closes a stated limit of the Jurist finding
(`purescript-julia/docs/PERFORMANCE-FINDING-2026-08-01-type-nesting.md`),
which said "nothing was checked on Pythia or Gnomon" and noted that
confirming it would make the type-nesting result the family's first genuinely
runtime-specific performance finding. It is.

What Pythia *does* show is the cost of an interpreter with no tail calls:

- `loop-naive` runs about 3.4× the per-iteration cost of `loop-fore`. Slower,
  not catastrophic — the honest contrast with Jurist's three orders of
  magnitude, and the reason the guidance is "prefer a host loop" rather than
  "Effect recursion is broken".
- `loop-tailrec` is the most expensive loop shape here (rel ~28 at n=10000),
  because `MonadRec`'s trampoline is real allocation on every step.
- `ffi-array` is nearly free relative to everything else — `sum()` is C. The
  FFI axis is not only a cost on this runtime; it is sometimes the fast path.

**One thing the lane needs on CPython specifically.** The runner raises the
recursion limit to 200,000 before importing the corpus. Python has no tail
calls, so a PureScript function that recurses n deep recurses n deep in
Python; at the default limit of 1000, `loop-naive` would raise
`RecursionError` and be recorded as DNF — a result that says nothing about
performance.

**Why the schedule is ordered the way it is.** The pathological shapes run
last, so a lane that hits its timeout still delivers most of the table, and
the corpus flushes stdout after every line so that a timeout yields both the
completed measurements and the identity of the shape that hung. Both came from
Jurist's first run; they cost nothing here and the corpus is shared.

## Files

| | |
|---|---|
| `src/Bench/Shapes.purs` | the shapes — **shared corpus**, byte-identical across the three backend repos |
| `src/Bench/Main.purs` | the harness and the schedule — also shared |
| `src/Bench/Clock.purs` | the one foreign: a monotonic clock, a stdout flush, and the two FFI probes |
| `src/Bench/Clock.js`, `ffi-py/Bench_Clock_foreign.py` | its implementations |
| `run_perf.py` | build, run, derive ratios, compare — **per-backend** |
| `baseline.json` | recorded ratios and checksums |

`src/Bench/Shapes.purs` and `src/Bench/Main.purs` are byte-identical to the
copies in `purescript-julia/perf/` and `purescript-go/perf/`; `md5` them
before changing either, and change all three together.
