# Python Backend Revisit — orientation brief

*Written 2026-06-11 by Claude (with Andrew) at the end of a marginalia session,
as a cold-start orientation for the fresh session that picks this up. Tracker:
note on Marginalia project #56 (purescript-python-new) records the intent.*

## The ask

Andrew: revisit this Python backend **with the experience gained from the
Julia backend (Jurist)** — "see if we can't do a better job on it."

## The thesis (why Jurist is the model)

Compare the two repos' `docs/` and the brief writes itself:

- **This repo** (purescript-python-new) is an *engineering* artifact: codegen
  works end-to-end (Hello World → Halogen WebSocket demo → cross-backend tests
  and benchmarks; it powers two showcase demos on the current polyglot site).
  Its docs are implementation notes: `PYTHON-FFI-STATUS.md`,
  `TAILREC-INLINING-ISSUE.md`, `UTF16-STRING-AUDIT.md`, `AFF-ASYNCIO-DESIGN.md`,
  `ROADMAP.md`. It answers "does PureScript run on Python?"

- **Jurist** (`../purescript-julia/`) answers a better question. Its docs are
  *design* documents: `julia-shaped-libraries.md`, `julia-hosted-purescript.md`
  (REPL-probe direction), `units-and-dimensions.md` (dimensional analysis in
  the type system), `jurist-demos-site.md`, `petri-composition-showcase.md`,
  plus a `design-decisions/` folder. The leap was **designing for the host
  language's strengths and idioms** — a meeting of two cultures, not a
  transpilation target.

## Candidate directions (port the philosophy back)

1. **Python-shaped libraries** — what is the numpy / pandas / dataclass story,
   asked the way Jurist asked the units question? What deserves a typed,
   honest PureScript surface because Python is where that work happens?
2. **Python-hosted PureScript** — notebook/REPL-resident, mirroring Jurist's
   julia-hosted direction. Relevant: marimo is among Andrew's reference clones
   (`~/work/afc-work/GitHub/`); and ShapedSteer wants cells-as-Python-
   computations via purepy (a standing ambition — don't foreclose
   heterogeneous cell backends).
3. **Finish Aff ↔ asyncio** — the design doc exists here already; it's the
   structured-concurrency honesty story.
4. **Hygiene backlog** — the existing issue docs (tailrec inlining, UTF-16
   strings, FFI gaps) become the engineering tail, not the headline.

## Read first

- `../purescript-julia/docs/design-decisions/` and the four design docs named
  above — absorb the *method*, not just the conclusions.
- This repo's `ROADMAP.md` + `AFF-ASYNCIO-DESIGN.md` for current state.
- Both are Haskell stack projects (compiler forks); build with stack.

## Wider context (one paragraph)

Andrew's world resolves to four megaprojects (Infovore / Humboldt / Atlantis /
Hylograph) plus Polyglot, which was re-founded 2026-06-11 as a *curator*: the
site that tells the "PureScript as honesty layer across runtimes — a
strongly-typed modern-day Tcl" story. It exhibits (via marginalia's new
`related` links, not ownership): Jurist (#219), purerl-tidal (#90, BEAM),
**this backend (#56, the Python exhibit)**, purescript-backend-wasm (#225,
evaluate its demo first), and Atlantis (#223, as a video demo). A better
Python backend is therefore also a better Polyglot exhibit.

## Operational notes

- Marginalia (project tracker) API lives at `http://andrews-mac-mini:3100`;
  log dated findings as notes on project **#56**; refresh its `description`
  per the living-summary protocol when the shape changes.
- If the tracker is unreachable over tailnet but the LAN works, Tailscale on
  the mini has stopped again: `ssh andrew@andrews-mac-mini.local` then
  `/Applications/Tailscale.app/Contents/MacOS/Tailscale up`.
