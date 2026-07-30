-- | Python keyword arguments, from a PureScript record.
-- |
-- | The first piece of Pythia's **companion library** — the third artefact a
-- | backend needs, alongside the lowering and each program's own FFI seam.
-- | See `docs/kb/architecture/backend-companion-libraries.md`.
-- |
-- | ## Why this and not something more general
-- |
-- | Keyword arguments are pervasive in the libraries a Python seam actually
-- | calls — `pp.runpp(net, algorithm="nr", max_iteration=20)`,
-- | `umap.UMAP(n_neighbors=15, min_dist=0.1)` — and PureScript's FFI cannot
-- | express them at all. Every seam either hard-codes one combination of
-- | options or hand-rolls its own dict convention.
-- |
-- | What this module deliberately is **not** is a dynamic `PyObject` call
-- | layer. That would invert ADR-0007: the typed description is supposed to
-- | cross the seam once, not be reassembled dynamically on the far side. The
-- | foreign stays hand-written and typed; this only makes an *options record*
-- | cross safely.
-- |
-- | ## Use
-- |
-- | ```purescript
-- | foreign import solveImpl :: EffectFn2 SolveSpec Kwargs SolveOutcome
-- |
-- | solve
-- |   :: forall r rl
-- |    . RowToList r rl
-- |   => BuildKwargs rl r
-- |   => SolveSpec -> Record r -> Effect SolveOutcome
-- | solve spec opts = runEffectFn2 solveImpl spec (kwargs opts)
-- | ```
-- |
-- | ```python
-- | def solveImpl(spec, kw):
-- |     return lambda: pp.runpp(_net_of(spec), **kw)
-- | ```
-- |
-- | Two properties earn their keep:
-- |
-- |   * **`Nothing` omits the argument entirely** rather than passing `None`.
-- |     Python libraries routinely distinguish "not supplied" from "supplied
-- |     as None", and a record of `Maybe`s is the natural way to say
-- |     "these options are optional".
-- |   * **`ToPy` restricts what may cross.** A field whose type has no
-- |     instance is a compile error, so a `Maybe`, a function or an ADT
-- |     cannot silently arrive on the Python side as a tag-tuple.
module Python.Kwargs
  ( Kwargs
  , PyValue
  , kwargs
  , noKwargs
  , debugKwargs
  , class ToPy
  , toPy
  , class ToPyField
  , toPyField
  , class BuildKwargs
  , buildKwargs
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Symbol (class IsSymbol, reflectSymbol)
import Prim.RowList (class RowToList, RowList)
import Prim.RowList as RL
import Record.Unsafe (unsafeGet)
import Type.Proxy (Proxy(..))

-- | A Python `dict` destined for a `**` splat. Opaque, and built only
-- | through `kwargs`, so its keys are always record labels and its values
-- | always came through `ToPy`.
foreign import data Kwargs :: Type

-- | A value that has a faithful Python representation.
foreign import data PyValue :: Type

foreign import emptyKwargs :: Kwargs

-- | Functional insert — returns a fresh dict, so `emptyKwargs` is never
-- | mutated and `Kwargs` values may be shared freely.
foreign import insertKw :: String -> PyValue -> Kwargs -> Kwargs

foreign import unsafeToPy :: forall a. a -> PyValue

-- | Deterministic rendering (keys sorted) for tests and error messages.
foreign import debugKwargs :: Kwargs -> String

-- | Types that cross to Python as themselves. The instance list IS the
-- | contract: these are the types whose Pythia representation is already
-- | the natural Python one, so the conversion is a coercion and the class
-- | is doing the safety work.
class ToPy a where
  toPy :: a -> PyValue

instance toPyInt :: ToPy Int where
  toPy = unsafeToPy

instance toPyNumber :: ToPy Number where
  toPy = unsafeToPy

instance toPyString :: ToPy String where
  toPy = unsafeToPy

instance toPyBoolean :: ToPy Boolean where
  toPy = unsafeToPy

instance toPyPyValue :: ToPy PyValue where
  toPy = identity

-- | Arrays are Python lists; the element type must itself be crossable.
instance toPyArray :: ToPy a => ToPy (Array a) where
  toPy = unsafeToPy <<< map toPy

-- | A nested record becomes a nested dict, which is what a library taking
-- | structured options expects.
instance toPyRecord :: (RowToList r rl, BuildKwargs rl r) => ToPy (Record r) where
  toPy = unsafeToPy <<< kwargs

-- | How one record field contributes to the dict. Split out from `ToPy`
-- | purely so `Maybe` can *omit* rather than convert.
class ToPyField a where
  toPyField :: String -> a -> Kwargs -> Kwargs

instance toPyFieldMaybe :: ToPy a => ToPyField (Maybe a) where
  toPyField label = case _ of
    Nothing -> identity
    Just a -> insertKw label (toPy a)

else instance toPyFieldPlain :: ToPy a => ToPyField a where
  toPyField label a = insertKw label (toPy a)

-- | Fold a record's `RowList` into a dict. Field order follows the
-- | `RowList`, which `purs` sorts by label, so the result is deterministic —
-- | irrelevant to Python's `**` but useful for testing.
class BuildKwargs (rl :: RowList Type) (r :: Row Type) where
  buildKwargs :: Proxy rl -> Record r -> Kwargs -> Kwargs

instance buildKwargsNil :: BuildKwargs RL.Nil r where
  buildKwargs _ _ acc = acc

instance buildKwargsCons ::
  ( IsSymbol label
  , ToPyField a
  , BuildKwargs rest r
  ) =>
  BuildKwargs (RL.Cons label a rest) r where
  buildKwargs _ rec acc =
    buildKwargs (Proxy :: Proxy rest) rec
      (toPyField label (unsafeGet label rec :: a) acc)
    where
    label = reflectSymbol (Proxy :: Proxy label)

-- | Turn a record of options into Python keyword arguments.
kwargs
  :: forall r rl
   . RowToList r rl
  => BuildKwargs rl r
  => Record r
  -> Kwargs
kwargs rec = buildKwargs (Proxy :: Proxy rl) rec emptyKwargs

-- | No keyword arguments — for a seam whose options are all defaulted.
noKwargs :: Kwargs
noKwargs = emptyKwargs
