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
type BusState =
  { id :: Int
  , name :: String
  , busType :: String
  , voltagePu :: Number
  , angleRad :: Number
  , loadMw :: Number
  , loadMvar :: Number
  , hasGenerator :: Boolean
  , x :: Number
  , y :: Number
  }

-- | A branch after a solve. Transformers arrive here too, with ids offset by
-- | 1000, because the frontend draws them the same way.
type LineState =
  { id :: Int
  , fromBus :: Int
  , toBus :: Int
  , loadingPercent :: Number
  , maxLoadingMva :: Number
  , inService :: Boolean
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

inServiceLines :: Array LineState -> Array LineState
inServiceLines = filter _.inService

-- | Branch endpoints for the in-service subgraph — the input to every
-- | connectivity question (`Grid.Graph`).
branchEndpoints :: Array LineState -> Array { from :: Int, to :: Int }
branchEndpoints = mapMaybe toEdge
  where
  toEdge l =
    if l.inService then Just { from: l.fromBus, to: l.toBus }
    else Nothing
