-- | The vocabulary of the grid analysis.
-- |
-- | FFI-free by construction: this module compiles under every backend, which
-- | is what keeps a JS parity column available for nothing (see the node
-- | column). Nothing here knows that pandapower exists — the only thing that
-- | does is `Grid.Solver`, the seam.
module Grid.Types
  ( CaseName(..)
  , caseName
  , LineId(..)
  , BusId(..)
  , LoadFactor(..)
  , loadFactor
  , Severity(..)
  , severityLabel
  , BusState
  , LineState
  , GeneratorState
  , SolveSpec
  , SolveOutcome
  , inServiceLines
  , branchEndpoints
  ) where

import Prelude

import Data.Array (filter, mapMaybe)
import Data.Maybe (Maybe(..))

-- | Name of a pandapower reference network. A newtype rather than a bare
-- | String so it cannot be confused with any other label crossing the seam.
newtype CaseName = CaseName String

derive newtype instance eqCaseName :: Eq CaseName

caseName :: CaseName -> String
caseName (CaseName s) = s

newtype LineId = LineId Int

derive newtype instance eqLineId :: Eq LineId
derive newtype instance ordLineId :: Ord LineId

newtype BusId = BusId Int

derive newtype instance eqBusId :: Eq BusId
derive newtype instance ordBusId :: Ord BusId

-- | Multiplier applied to every load before the solve. The knob that makes
-- | the exhibit an experiment rather than a fixture: at 0.7 the IEEE 30-bus
-- | case is comfortable, by 1.0 a line is over its thermal rating.
newtype LoadFactor = LoadFactor Number

loadFactor :: LoadFactor -> Number
loadFactor (LoadFactor n) = n

-- | How bad a network state is.
-- |
-- | An ADT, not a String: the alternatives are closed, and the classification
-- | is ours to make (`Grid.Severity`) rather than something the solver hands
-- | us. It was `severity :: String`, decided in Python.
data Severity = Safe | Warning | Critical

derive instance eqSeverity :: Eq Severity

instance ordSeverity :: Ord Severity where
  compare a b = compare (rank a) (rank b)
    where
    rank = case _ of
      Critical -> 0
      Warning -> 1
      Safe -> 2

instance showSeverity :: Show Severity where
  show = severityLabel

-- | Wire form. Kept explicit so the JSON shape is a decision, not a
-- | consequence of how the backend happens to encode constructors.
severityLabel :: Severity -> String
severityLabel = case _ of
  Safe -> "safe"
  Warning -> "warning"
  Critical -> "critical"

-- | A bus after a solve. `voltagePu` is the per-unit magnitude — the quantity
-- | the voltage half of the severity rule reads.
-- |
-- | `energised` says whether that voltage is a *result*. A bus cut off from
-- | every source has no defined voltage, and the solver says so by returning
-- | NaN. See the note on `LineState.energised`: the flag exists so that no
-- | NaN ever reaches this side of the seam.
type BusState =
  { id :: Int
  , name :: String
  , busType :: String
  , voltagePu :: Number
  , angleRad :: Number
  , loadMw :: Number
  , loadMvar :: Number
  , hasGenerator :: Boolean
  , energised :: Boolean
  , x :: Number
  , y :: Number
  }

-- | A branch after a solve. Transformers arrive here too, with ids offset by
-- | 1000, because the frontend draws them the same way.
-- |
-- | **`inService` and `energised` are different things, and conflating them
-- | was a real bug.** `inService` is an input: we chose to open this branch.
-- | `energised` is an output: the branch is closed, but it ended up inside an
-- | island with no source, so it carries no defined flow.
-- |
-- | The distinction has to exist because `Ord Number` in PureScript is not a
-- | total order and does not pretend to be. `compare` on Number is
-- | `unsafeCompare`, which tests `<`, then `==`, and otherwise answers `GT` —
-- | so `nan > 100.0` is `true`, on every backend, exactly as it is in the
-- | JavaScript reference. A de-energised branch reporting NaN loading
-- | therefore read as "over its thermal rating" and was tripped by the
-- | cascade, which is how this exhibit came to claim seven lines lost from an
-- | outage that actually loses three.
-- |
-- | The fix is at the seam, not here: it substitutes a defined value and sets
-- | `energised` false, so the core never sees a NaN to compare. This module
-- | assumes NaN-free `Number`s and that assumption is now the seam's contract.
type LineState =
  { id :: Int
  , fromBus :: Int
  , toBus :: Int
  , loadingPercent :: Number
  , maxLoadingMva :: Number
  , inService :: Boolean
  , energised :: Boolean
  , pFromMw :: Number
  , qFromMvar :: Number
  , isTransformer :: Boolean
  }

type GeneratorState =
  { id :: Int
  , bus :: Int
  , pMw :: Number
  , qMvar :: Number
  , inService :: Boolean
  , pMaxMw :: Number
  }

-- | Everything the seam needs to run one solve. Self-contained on purpose:
-- | each call is independent, so there is no mutable network handle shuttling
-- | across the boundary and no ordering coupling between calls.
type SolveSpec =
  { caseName :: String
  , loadFactor :: Number
  , linesOut :: Array Int
  , loadsOut :: Array Int
  }

-- | Everything one solve yields. `converged` false still carries topology, so
-- | a diverged case is analysable rather than empty.
type SolveOutcome =
  { converged :: Boolean
  , name :: String
  , baseMva :: Number
  , buses :: Array BusState
  , lines :: Array LineState
  , generators :: Array GeneratorState
  , totalLoadMw :: Number
  , totalGenMw :: Number
  , totalLossMw :: Number
  }

-- | Branches carrying a defined flow: closed, and inside an energised island.
-- |
-- | Every loading figure the analysis reads comes through here. A closed
-- | branch in a dead island has no loading, and must not be averaged, ranked
-- | or compared with one that has.
inServiceLines :: Array LineState -> Array LineState
inServiceLines = filter \l -> l.inService && l.energised

-- | Branch endpoints for the in-service subgraph — the input to every
-- | connectivity question (`Grid.Graph`).
branchEndpoints :: Array LineState -> Array { from :: Int, to :: Int }
branchEndpoints = mapMaybe toEdge
  where
  toEdge l =
    if l.inService then Just { from: l.fromBus, to: l.toBus }
    else Nothing
