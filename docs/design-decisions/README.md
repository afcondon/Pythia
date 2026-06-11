# Design Decisions

This directory records the significant architectural decisions for purepy —
the PureScript → Python backend — as lightweight
[ADRs](https://adr.github.io/) (Architecture Decision Records).

Each record captures **one** decision: the context that forced it, the
decision itself, its consequences, and the alternatives that were rejected
and why. A record's original text is never deleted-and-replaced — history is
preserved in place (see [Maintaining records](#maintaining-records)). A
genuinely *reversed* decision is retired by a new record that supersedes it,
not by rewriting the old one.

The format and maintenance discipline are deliberately the same as the
sibling backends' — [Jurist](../../../purescript-julia/docs/design-decisions/)
(PureScript → Julia) and
[`purescript-backend-wasm`](https://github.com/katsujukou/purescript-backend-wasm)
— so the wider PureScript-backends family stays legible to a reader (or a
contributing agent) moving between them.

## Format

```plain
# <NNNN>. <Title>

- Status: Proposed | Accepted | Superseded by <NNNN>
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
## Alternatives considered
```

## Maintaining records

When a record drifts from the implementation, **do not delete and replace the
original text.** Keep the original readable as history and mark the change in
place:

- **Correction / progress addendum** — strike the obsolete text with `~~…~~`
  and append a dated note, e.g. `> **Progress (YYYY-MM-DD):** …`.
- **Status promotion** — keep the old status struck through and add the new
  one with a dated rationale, e.g.
  `- Status: ~~Proposed~~ **Accepted** _(YYYY-MM-DD: implemented in …)_`.
- **Reversal** — a genuinely overturned decision is retired by a new record
  that supersedes it (`Status: Superseded by <NNNN>`), not by rewriting it.
- **The index below is the exception** — it is edited by direct overwrite, as
  a derived table that must always show each record's current status.

## Index

| # | Title | Status |
| - | - | - |
| 0001 | [Reboot as a Jurist-sibling from-scratch compiler](0001-reboot-as-jurist-sibling.md) | Accepted |
| 0002 | [Expression emission with module-level lambda lifting](0002-expression-emission-lambda-lifting.md) | Accepted |

## Scope

purepy is a CoreFn → Python code generator (Haskell; the `purepy` binary),
sibling of [Jurist](../../../purescript-julia/) (`purejl`). It consumes the
CoreFn JSON that `purs` emits and writes one Python module per PureScript
module. The repo's first incarnation (2026-02, two parallel compiler
implementations) reached Hello-World-to-Halogen-demo coverage; record 0001
reboots it on the Jurist architecture with the differential conformance
suite as the evidence backbone.

The authoritative, up-to-date status lives in the repo
[`README.md`](../../README.md); these records capture *why* the backend is
shaped the way it is. The design direction (what the backend is *for*) lives
in [`../python-shaped-libraries.md`](../python-shaped-libraries.md).
Frontiers not yet decided (runtime representation, TCO strategy, module
layout, backend-optimizer integration, Asyncio) will get records as they are
settled.
