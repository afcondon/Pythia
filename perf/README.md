# The performance canary

The differential suite answers *does this mean the same thing on both
runtimes?* This lane answers the other half: *and does it still cost what it
cost yesterday?*

```bash
cd perf
python3 run_perf.py                    # build, run, check
python3 run_perf.py --skip-build --echo # re-run, streaming
python3 run_perf.py --update-baseline   # re-record THIS machine's baseline
                                        # (say why in the commit)
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
n=10000:

| column | meaning |
|---|---|
| `rel` | steady(shape) / steady(calibration) — cost relative to a plain host loop on the same runtime |
| `f/s` | first / steady — how much of the first call is compilation |

Machine speed cancels within a run. It does not make the baseline portable
between machines, which is the next section's subject. `f/s` is the
type-nesting signal in one number: ~1 on a runtime that does not compile per
call site, and large — and *staying* large as n grows — exactly where
specialisation is happening.

## Checksums gate; timings report

Every shape returns an `Int` checksum, and the runner diffs checksums across
backends **before it looks at a single timing**. A benchmark that computes
the wrong answer quickly is the classic way for a performance suite to stay
green while the thing it measures rots.

## Drift gates too, but only on rows that can carry a gate

Timing drift is a failure as well (`--gate-drift`, on in `bin/conformance.sh`).
It was not, when the lane was first built, and what changed is worth stating
precisely, because it is not what it looks like.

**The tolerance did not change.** It is still 2×. What changed is the
population it applies to, and the size of the thing everything is divided by.

The original calibration was `loop-fore` at n=1000, which at five reps is six
thousand iterations — not enough work for a tiering JIT to finish tiering.
The JS reference measured that shape at 114, 135, 167, 188 and 196 µs on the
same idle machine on the same day. Every `rel` in the table is divided by that
number, so the lane's noise floor was being set by its own denominator. The
tell was visible in the baseline and went unread: `loop-fore@10000` recorded
`rel` 10.4 on Jurist — linear in n, as a host loop should be — but 6.3 on JS,
not because the JS loop is sublinear but because its denominator was slow.
At n=10000 the calibration reads 1020/1027/1023 µs across runs.

That fixed the denominator but not the tail. Six back-to-back runs of all
three backends (2026-08-01, idle M4 MBP) put the worst run-to-run spread at:

| population | rows | median | 90th | worst |
|---|---|---|---|---|
| every measured row | 258 | 1.13× | 1.35× | **5.74×** |
| largest n of each shape | 78 | 1.10× | 1.26× | 1.69× |
| steady ≥ 50 µs | 123 | 1.10× | 1.27× | 5.74× |
| **both — the gated population** | 56 | 1.10× | 1.21× | **1.69×** |

A 2× gate over the first row would have fired on noise nearly every run. Over
the last it has 1.18× of headroom over the worst thing noise managed in six
tries. So the runner marks a row **gated** when it is both:

1. **the largest n of that shape** — the smaller sizes exist to show the
   *curve*, superlinearity and `f/s` growth, which is a diagnostic and not a
   threshold; and
2. **above `GATE_MIN_STEADY_US`** (50 µs) — below that, scheduler noise and
   timer resolution dominate. `ffi-array@1600` on the JS reference is ~20 µs
   and swings 1.5× between runs while doing identical work.

Ungated rows are still measured, still printed, and still reported as drift —
they just carry `(report only)` and cannot fail a build. Nothing is hidden.

The gate flag is decided when the baseline is **recorded**, and travels in it.
Recomputing it per run would make a shape near the 50 µs line gate on one run
and not the next. It is therefore a property of the recording machine: on a
slower box this excludes rows that would have been measurable there, which
costs a little coverage and never invents an alarm.

Two consequences worth knowing:

- `fold-array` is never gated on any backend, by design. It is `fold-list`'s
  control rather than a subject, and array traversal is gated through
  `map-array` instead.
- `ffi-array` and `string-join` run to n=12800 for no reason other than this.
  At 1600 both sat under the floor on every backend, so neither was gated
  anywhere — and `ffi-array` is one of the two shapes that measure the FFI
  axis this corpus was built around. **A shape that cannot fail the gate is
  not protected by it.**

Tighten toward the 90th percentile once a few weeks of CI runs say what the
tail really looks like; six samples underestimate it.

## The speed index, and a baseline per machine (2026-10-27)

Two holes, both found in the October review (`REVIEW-2026-10.md`, X3 c and e).

**A uniform change was invisible.** Every `rel` is divided by the same run's
`loop-fore`, which this backend also compiles. A code-generator change that
makes every shape 20 % faster makes the calibration 20 % faster too, and every
ratio stays put. That is what Pythia#3 (`functools.partial` for `_mk`) did:
about −20 % on every closure-heavy shape, and the gate said nothing.

So each backend now also gets a **speed index** per run: the geometric mean,
over its gated shapes, of `steady(backend) / steady(js)` for the same shape in
the same run. The JS reference is compiled by `purs`, which nothing in this
repo changes, so a uniform change here moves the index by its own size. The
mean over about ten shapes is also much quieter than any one ratio, which is
what lets the tolerance be tight (`INDEX_TOLERANCE = 1.10`).

Each run measures every backend three times, interleaved by round (`js`,
`py`, `backend-py`, `js`, …), and uses the per-shape median (`--repeat`,
default 3). Interleaving matters as much as the median: a shift in machine
load during the run lands on the numerator and the denominator alike.

Noise on the Mac Mini M4, which is never idle (other sessions build there):

| runs | `py` index vs baseline | `backend-py` index vs baseline |
|---|---|---|
| 10 single runs, light load | 16.95–18.07 (spread 1.066×) | 2.55–2.74 (spread 1.072×) |
| 6 runs at `--repeat 3`, heavy load | 0.944–1.038× | 0.925–1.004× |

Pythia#3 replayed through the gate, against the same machine's baseline:

| runs | `py` index vs baseline | verdict |
|---|---|---|
| 3 single runs | 0.887×, 0.887×, 0.865× | MOVED, gate fails |
| 3 runs at `--repeat 3`, heavy load | 0.837×, 0.854×, 0.898× | MOVED, gate fails |

The per-shape check on every one of those runs said "no shape moved more than
2.0x". `backend-py` stayed inside the tolerance (0.92–1.01×), as it should:
the change is in purepy's runtime prelude.

So `INDEX_TOLERANCE = 1.10` separates the two on this machine, but under
heavy load the margin is a few percent, not a comfortable one. The runner
therefore prints each round's own index and its spread. That is the run's
noise, measured rather than assumed. When the spread is wider than the
tolerance, the verdict is labelled **NOISY**: that run cannot vouch for it,
and it should be re-run on a quieter machine. A change smaller than about
10 % is below what this gate can see on the Mini; say so rather than claim it.

**The baseline did not transfer.** The ratios were meant to be
machine-independent. The first run on GitHub's x86 runners put gated JS
ratios at 2.17× and 0.38× of the M4 baseline with nothing changed, and the
index is a cross-runtime ratio, which is even less likely to transfer: V8
and CPython do not speed up together across CPUs. So a baseline belongs to
the machine that recorded it: `baselines/<host>-<cpu>.json`, chosen by
`machine_id()` in `run_perf.py`. On a machine with none, the drift gate says
**NOT RUN**, naming the machine and the baselines that do exist, in the log
and as a GitHub annotation. Every CI runner is such a machine, because its
host name is fresh on each run. Checksums gate everywhere.

The M4 MBP's old `baseline.json` is gone: it could not say which machine it
spoke for. Record one there with `--update-baseline` to gate on the MBP.

**The optimizer lane is in the canary.** `backend-py` compiles its own code,
so it gets its own index, ratios and checksums. It runs whenever
`../purescript-backend-optimizer` is checked out, and says NOT RUN when it is
not, which is every CI runner today.

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
| `baselines/<machine>.json` | one machine's recorded ratios, speed indices and checksums |

`src/Bench/Shapes.purs` and `src/Bench/Main.purs` are byte-identical to the
copies in `purescript-julia/perf/` and `purescript-go/perf/`; `md5` them
before changing either, and change all three together.
