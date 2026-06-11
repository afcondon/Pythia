# 0001. Reboot as a Jurist-sibling from-scratch compiler

- Status: Accepted
- Date: 2026-06-11

## Context

The repo's first incarnation (2026-02) proved the concept — CoreFn → Python
codegen working end-to-end, Hello World through a Halogen WebSocket demo,
stack-safe `tailRec`, native `Control.Monad.Asyncio` — but the 2026-06-11
revisit probes (see `../python-shaped-libraries.md`, "The engineering tail")
found it in poor structural shape:

- **Two parallel compiler implementations**, neither designated canonical: a
  Haskell CoreFn→Python generator (`src/`, ~2.6k lines, the most recent
  codegen fixes) and a backend-optimizer-based PureScript one
  (`backend-python/`, ~2.4k lines, carrying the Asyncio and tailRec work).
- **No conformance evidence**: the cross-backend diff suite is 5 modules and
  currently unrunnable on either side (test-project path-depends on the
  vanished psd3 libraries; the committed generated output is stale and
  crashes on an FFI arity drift).
- **No decision records**: the docs are good implementation notes, but the
  decisions inside them are not recorded, so the two-implementations
  ambiguity persisted silently.

Meanwhile the sibling Jurist (`../../../purescript-julia/`) demonstrated, in
six days and 68 commits (2026-06-05 → 06-11), what the same task looks like
with current method: a from-scratch Haskell CoreFn→Julia generator of
**1.8k lines** reaching **422/426 byte-identical** differential conformance,
with an ADR trail, a divergence ledger, an FFI shim doctrine, and a
design-doc-led library direction. Both Andrew's and Claude's capabilities
when the original port was written were more limited than what produced
Jurist; the original port is an artifact of that earlier capability level.

## Decision

**Reboot the backend as a from-scratch sibling of Jurist, in place in this
repo.** Concretely:

1. **New compiler, purejl skeleton.** A fresh Haskell CoreFn → Python
   generator modeled directly on purejl's architecture (`Make` /
   `CodeGen` / `Foreigns` with built-in shims / minimal CLI). The binary
   keeps the name `purepy`. Neither existing implementation is salvaged as
   the base.
2. **Conformance first (red/green).** Jurist's `test-suite/` — the
   foreign-free `Test.*` corpus, the stdlib-only differential runner, the
   `KNOWN_DIVERGENCES` ledger — is adopted as a shared family corpus before
   the new compiler exists. The suite starts red; codegen work proceeds
   module by module until green. No feature lands without the suite
   passing.
3. **ADR discipline from record 0001** (this file), in the family format,
   so decisions (runtime representation, TCO, module layout, FFI shims)
   are recorded as they are made rather than backfilled.
4. **The old work transfers as knowledge, not code.** `UTF16-STRING-AUDIT.md`
   seeds the Python divergence ledger; `TAILREC-INLINING-ISSUE.md` informs
   the TCO record; `AFF-ASYNCIO-DESIGN.md` remains the async direction;
   the FFI canary idea and the benchmark harness shapes are kept. The two
   old implementations (`src/`, `backend-python/`) are retained read-only
   as reference until the new compiler reaches corpus parity, then retired
   to git history.
5. **Direction per the design doc.** What the backend is *for* is set by
   `../python-shaped-libraries.md` (the verb-matrix middle column, typed
   numpy handles, the DuckDB query eDSL) — codegen exists to serve that,
   which keeps generated-code micro-performance from becoming a false
   priority (hot loops live in numpy/sympy/DuckDB, per the measured 145×
   callback receipt).

## Consequences

- The family gains symmetry: two sibling backends with the same
  architecture, the same ADR format, and (intended) the same conformance
  corpus — one kit, per-backend divergence ledgers. An agent oriented in
  either repo is oriented in both.
- Jurist's conformance number gives the reboot a concrete, comparable
  target: the suite defines done.
- The Python column of the family verb matrix (differentiate via sympy,
  integrate via lambdify+scipy — receipts in the design doc) becomes
  buildable on a compiler whose semantics are evidenced, not hoped.
- Cost accepted: re-deriving codegen that the old implementations already
  had (records, pattern matching, recursion). Jurist's six-day receipt and
  the transplantable skeleton bound this cost; the corpus makes progress
  measurable.
- Until parity, the repo temporarily holds three compilers. The README must
  point newcomers at the new one.

> **Progress (2026-06-11):** Steps 2 and 3 are standing. `test-suite/` holds
> the corpus copied from Jurist (10 `Test.*` modules, registry 57.1.0,
> foreign-free) and the adapted `run_tests.py` (expects
> `output-py/<Module_Name>.py`, dots → underscores, case preserved; `main` an
> Effect thunk). First run: JS side green, Python side **0/0 with 10 module
> errors** — the intended red. Baseline receipt for the cost-accepted bullet:
> the *old* compiler, run against the same corpus, crashes on **9 of 10**
> modules (e.g. `ModuleNotFoundError: control_extend_foreign` — it emits
> imports for foreign modules it never provides; only `Test.Uncurried` runs).
> The salvage option was weaker than it looked when this record was written.

> **Progress (2026-06-11, same session): corpus parity reached.** The new
> compiler (purejl skeleton: `Make`/`CodeGen`/`Common`/`Foreigns`, ~2k
> lines, both old implementations moved to `attic/`) walked the shared
> corpus from red to **422/426 byte-identical, 4 ledger divergences
> (INT64 ×2, ASTRAL ×2 — exactly as pre-seeded), 0 failures, 0 module
> errors** — the same score as Jurist on the same corpus. One
> Python-specific architectural decision was forced en route (CPython's
> nesting caps → module-level lambda lifting, record
> [0002](0002-expression-emission-lambda-lifting.md)), and the strict
> per-name foreign imports caught a genuinely missing shim
> (`Effect.Ref.newWithSelf`) at import time. Per point 4, the old
> implementations are now eligible for retirement from `attic/` to git
> history.

## Alternatives considered

- **Salvage the Haskell `src/` implementation.** It has the latest codegen
  work, but no conformance harness, known FFI arity drift, and a 1.4k-line
  `Make.hs` that would need restructuring toward the purejl shape anyway.
  Retrofitting method onto it costs more than transplanting the method-built
  sibling, and keeps the undecided dual-implementation history alive.
- **Salvage the backend-optimizer PureScript implementation
  (`backend-python/`).** The optimizer path is genuinely attractive
  (uncurrying, inlining — the `purescript-backend-erl` precedent), but it
  optimizes for generated-code speed, which the Python-shaped doctrine
  deliberately de-emphasizes; it breaks family symmetry with Jurist; and
  its Asyncio/tailRec value transfers as design knowledge regardless.
  Backend-optimizer integration remains an open frontier a future record
  may revisit — consuming optimized IR is compatible with this reboot.
- **Reconsider the runtime conventions wholesale (e.g. `__slots__` classes,
  match statements, snake_case mangling) as part of the reboot decision.**
  Deferred, deliberately: those are exactly the per-decision records the
  ADR trail exists for (the Jurist sequence settles representation in its
  own 0001). This record decides only the architecture and the method.
