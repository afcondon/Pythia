# `backend-py` — the optimizer-consumer lane for Pythia

A PureScript program that consumes
[`purescript-backend-optimizer`](../../purescript-backend-optimizer)'s optimized
IR (`BackendSyntax` / `NeutralExpr`) and lowers it to Python.

There are **two implementations in this repo on purpose** — see
[ADR-0003](../docs/design-decisions/0003-two-implementations.md). `purepy`
(`../src`, Haskell, raw CoreFn) is the correctness **oracle**; this is the
consumer lane. Correctness claims rest on the oracle, and the method is that
both lanes run the same corpus and are diffed against the same JavaScript
reference.

## Status

```
20/20 green   (17 identical + 3 ledger-only)         ./run_conformance.sh
343/347 = 98.8%   tests/purs/passing @ v0.15.15      purs-corpus/run_corpus.py
```

The oracle lane (`purepy`) scores 341/347 on the same corpus, run the same day
with the same harness. This lane fixes **four** — `3957` and `PartialTCO` (TCO),
`StringEscapes` (lone surrogates), `BigFunction` (paren nesting) — and regresses
**two**, both of them upstream in the optimizer's CoreFn JSON decoder rather
than in this lowering (`NegativeIntInRange`, `StringEdgeCases`; see
[ADR-0003](../docs/design-decisions/0003-two-implementations.md)). Two failures
are common to both lanes: `2136` (`Int` wrapping — a representation decision,
Gate C9's to settle) and `TCOMutRec` (join points, below).

## What it does not own

**No runtime, and no foreign shims.** `backend-py` emits one Python file per
PureScript module using `purepy`'s naming, so `_purepy_runtime.py` and every
`<Module>_foreign.py` are produced by `purepy` and copied in unmodified. This is
deliberate and evidence-driven: Gnomon kept two ~2,400-line Go runtimes, they
diverged by two symbols, and only a red CI caught it. Here a fork is not
available.

Three helpers were added to the *shared* runtime for the PrimOps the IR lowers
with no foreign to fall back on — `_int32`, `_int_div`, `_num_div` — holding
exactly the semantics `Data_EuclideanRing_foreign` and `Data_Int_Bits_foreign`
hold for the oracle. One definition each, both lanes.

## Statement-oriented, and why that matters

`purepy` is expression-oriented and needs module-level lambda lifting to stay
under CPython's ~200-deep parenthesis cap
([ADR-0002](../docs/design-decisions/0002-expression-emission-lambda-lifting.md)).
This lane emits statements instead: a `Let` is an assignment, a `Branch` is an
`if`/`elif` chain, an `EffectBind` chain is a flat run of statements. There is
no lifting pass, and `BigFunction` — which defeats the oracle — compiles.

The cost is that **an IR scope is no longer a target scope**, which
`backend-go` (the template this was ported from) gets for free by making every
`Let` an IIFE. Four collision classes follow, all handled in
`Codegen/Python.purs`: sibling IR scopes flattened into one Python function,
top-level bindings sharing module scope, generated loop dispatchers being
module-level `def`s, and generated names sharing a namespace with user
identifiers. The first three were found by the corpus rather than by inspection;
the fourth was closed by analogy with the module-alias prefix, which is why
every generated name carries a reserved `_ps_` prefix.

## Tail calls

Self-recursive and directly mutually-recursive groups lower to the shared
runtime's existing `_tco_run` — no runtime change, and no `while` loop.
The function-call-per-iteration shape is load-bearing: a Python loop body shares
one frame, so a closure created inside it would capture the last iteration's
bindings. This is the same reason `purepy` shaped its own trampoline that way,
and the same reason purs shapes JS TCO that way.

**Join points too.** A helper written in a `where` *nested* inside a loop member
— `TCOMutRec`'s `tco1` defines `g` inside `f`, and they tail-call each other —
is folded into the same dispatch group as another branch, so the cross-calls
become jumps rather than stack calls. All four of `TCOMutRec`'s positive cases
run in flat stack; verified byte-identical to the JavaScript reference at depth
100,000 and still correct at 1,000,000.

The mechanism worth knowing about is the **register file, which is keyed by
local rather than by position**. Folding a join point in lifts it out of the
member it was written inside, and it may have captured variables from there
(`tco4`'s `g y' = f (x + 2) y'` reads `f`'s parameter `x`). A jump leaves the
frame, so those have to travel too — one slot per distinct local, and `x` gets
the same slot whether it arrives as `f`'s parameter or as `g`'s capture. The
register file is bound **once** and reused by every branch: `bindLocal` enforces
module-wide uniqueness (hazard 1 above), so binding per branch would rename the
second branch's copy away from the first's.

`TCOMutRec` as a whole still fails, but no longer for a reason in this lane: it
also asserts that four *non*-TCO-able shapes must overflow, and the optimizer
inlines two of those helpers away into plain self-loops that complete. See
[ADR-0003](../docs/design-decisions/0003-two-implementations.md).

## Usage

```bash
spago build

# emit Python for a whole corefn output directory, pruned to one entry point
node run.mjs --corefn-dir ../test-suite/output --output-dir out --main Test.ADTs

# the runtime and the foreigns come from the oracle lane
cp ../test-suite/output-py/_purepy_runtime.py out/
cp ../test-suite/output-py/*_foreign.py out/

cd out && python3 entrypoint.py
```

`--main` prunes: every binding unreachable from that module's `main` is dropped,
along with any module left empty.

## Conformance

```bash
./run_conformance.sh                # builds purepy first, then this lane
./run_conformance.sh --skip-purepy  # reuse ../test-suite/output-py
```

The `Test.*` corpus is shared with `purepy`, Jurist and Gnomon — one family
conformance kit, per-backend divergence ledgers.

## Layout

- `src/Main.purs` — CLI, entry reachability, module assembly
- `src/PureScript/Backend/Optimizer/Codegen/Python.purs` — the emitter
- `src/PureScript/Backend/Optimizer/Codegen/Python/Builder.purs` — the build
  driver, a verbatim port of backend-es's (nothing ES-specific in it)
- `src/PureScript/Backend/Optimizer/Reachability.purs` — entry pruning, shared
  verbatim with `backend-go` and belonging upstream
