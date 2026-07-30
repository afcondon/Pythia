# Pythia's companion library

The **third artefact** a backend needs, alongside the lowering and each
program's own FFI seam: PureScript modules whose foreigns are supplied by the
*backend*, giving typed access to the target runtime. Every program on Pythia
wants them and none of them should write them.

This is not a novelty. PureScript has had this tier all along and never named
it — `Data.List` is the portable container, `Data.Array` is *JavaScript's*
container reached through foreigns, and `Data.Array` is what everybody
actually writes. purerl names the tier explicitly with `Erl.Data.Map`,
`Erl.Data.List`, `Erl.Atom`. Full argument in
`docs/kb/architecture/backend-companion-libraries.md` (the `docs` repo).

## Layout

```
python-ffi/      the library. .purs here; the Python foreign lives in the
                 backend's builtin catalogue (Foreigns.hs), exactly as the
                 core libraries work — upstream .purs, backend-supplied
                 foreign.
laws/            the test lane, and run.sh that drives it.
```

To depend on it, add a path `extraPackages` entry:

```yaml
workspace:
  extraPackages:
    purepy-python:
      path: ../../purescript-python/companion/python-ffi
```

## What is here

| module | what it buys |
|---|---|
| `Python.Kwargs` | Python keyword arguments from a PureScript record. `Nothing` **omits** an argument rather than passing `None`; `ToPy` rejects unmarshallable field types at compile time. |

Next, in rough order of how much each would unblock: `None`/`Maybe` at return
positions, exceptions as `Either` at the seam (the standard-library half of
this landed as `Effect.Exception`), NumPy buffers, iterators and `with`-blocks,
and `Python.Data.Dict`.

## Why it has its own test lane

**The differential corpus cannot test any of this.** Its whole method is
running the same FFI-free source on two backends and diffing byte-for-byte,
and a companion library has no JavaScript counterpart to diff against — by
construction, since not compiling under the JS backend is the *defining
property* of the tier.

So `laws/` makes the assertions you can make against a single runtime: round
trips, omissions, orderings, and — the one that actually matters — that the
dict really does splat into a Python call, including into a fixed-arity
function with no `**kwargs`, which is what a real library entry point looks
like.

```bash
./companion/laws/run.sh     # or ./bin/conformance.sh, which runs both lanes
```

Without this lane, "we have a conformance suite" would imply a coverage it
does not have. That is the same lesson as the `Data.Map` bug in new clothes:
coverage has to be counted by what actually gets compiled and run, never by
what the feature is called.
