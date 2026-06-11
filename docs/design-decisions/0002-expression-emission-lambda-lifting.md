# 0002. Expression emission with module-level lambda lifting

- Status: Accepted
- Date: 2026-06-11

## Context

The reboot (0001) transplants Jurist's expression-oriented emitter: every
CoreFn expression compiles to one Python expression — curried unary
lambdas, ternary chains for case alternatives, walrus-in-tuple IIFEs for
let-scoping, tag-tuples for ADTs. The first run proved the approach (72/72
identical on the modules that parsed) and exposed the Python-specific
wall: **CPython's tokenizer caps parenthesis nesting at ~200 and
indentation at 100 levels.** A monadic do-block nests its continuation
lambda inside each bind's call parens, so `Test.Numbers` (~110 binds)
died with `SyntaxError: too many nested parentheses`. No amount of paren
thrift fixes this — a lambda's body is textually inside every enclosing
call — and nested `def`s hit the indentation cap the same way.

## Decision

Keep the expression-oriented emitter, and add **module-level lambda
lifting**: every CoreFn `Abs` is hoisted to a one-line module-level
`def _lamN(free..., arg): return <body>` carrying its free LOCAL
variables as leading parameters (module-level names are Python globals
inside defs and need no passing). The use site is `_lamN` when the
lambda is closed, else `_mk(_lamN, free...)` — a runtime helper restoring
a unary closure. Continuation depth becomes flat sibling defs.

Lifting captures free variables by value at closure-creation time, which
matches CoreFn semantics everywhere except **recursive local bindings**,
whose names must resolve late (they are unbound when their own lambda is
created). Those keep their outermost lambda chain inline — Python
closures look free names up at call time — and lift only inside the
body, which runs after the binding completes. TCO'd bindings need no
exemption: the dispatch-loop body never references the binding (self
calls compile to `(1, (args,))` tuples). Top-level recursion needs none
either: defs read module globals late.

Two supporting scope rules, verified by probe before adoption:

- **Pattern bindings live in per-alternative IIFEs.** A walrus binding
  anywhere in a lambda makes the name local THROUGHOUT that lambda, so
  binding a pattern variable directly in the case-dispatch lambda would
  shadow an outer binding for every other alternative (UnboundLocalError
  when one reads the outer name). `(lambda: (binds..., body)[-1])()`
  restores exact IIFE scoping.
- **Free-variable over-approximation is safe.** The analysis intersects
  all local references in the body with the bound-locals environment;
  names rebound inside the body may be passed needlessly, but every
  rebinding context (lifted def, IIFE, per-alternative IIFE) is a fresh
  Python scope that shadows correctly.

## Consequences

- The shared corpus went from `SyntaxError` to **422/426 byte-identical
  (4 ledger divergences, 0 failures)** — the same score as Jurist on the
  same corpus, in the same session the wall was found.
- The strict per-name foreign import this emitter pairs with
  (`from X_foreign import (a, b, c)`) is an import-time FFI canary: it
  caught `Effect.Ref.newWithSelf` missing from the shims, which Jurist's
  `include`-based loading would surface only on first call.
- Cost: one `_mk` call (a closure) per closure creation with free
  variables; one extra Python frame per lifted-lambda invocation.
  Acceptable under the python-shaped-libraries doctrine — hot loops
  belong to numpy/sympy/DuckDB, not to generated glue.
- Residual depth: ternary chains still nest linearly in the number of
  alternatives of a single case, and right-nested operator chains nest
  linearly in their length. Both are far below the cap in practice; if a
  real program hits them, the relief is ANF-style hoisting of App
  arguments into IIFE siblings (no scope issues, fresh names), recorded
  here as the known next step.

## Alternatives considered

- **Full statement-form code generation** (the first incarnation's
  approach: an AST, assignments, if/return). Solves nesting only if
  combined with lifting anyway (nested defs hit the indent cap), costs
  the line-for-line correspondence with the Jurist emitter, and is a
  much larger generator. The expression form + lifting gets the same
  flatness with a State monad and ~60 lines.
- **Raising CPython's limits.** The tokenizer caps are compile-time C
  constants, not configurable.
- **ANF alone** (hoisting arguments into walrus siblings without
  lifting). Cannot help: a lambda's body text is inside the lambda
  wherever the lambda sits; only hoisting to statement context flattens
  it.
