-- | N-1 contingency analysis: take out one branch at a time and ask whether
-- | the network still stands.
-- |
-- | The loop, the ordering and the verdict are all here. Previously the whole
-- | of this was `foreign import runContingency`, and this module was thirty-nine
-- | lines of type alias over a hundred and thirty-six lines of Python.
module Grid.Contingency
  ( ContingencyCase
  , ContingencyReport
  , analyse
  , candidateBranches
  ) where

import Prelude

import Data.Array (filter, length, sortBy)
import Data.Traversable (traverse)
import Effect (Effect)
import Grid.Severity (Limits, classify, worstLoading, worstVoltage)
import Grid.Solver (baseSpec, solve, withLinesOut)
import Grid.Types (LineState, Severity(..), SolveOutcome, severityLabel)

type ContingencyCase =
  { lineId :: Int
  , isTransformer :: Boolean
  , converged :: Boolean
  , maxLoading :: Number
  , worstOverloadLine :: Int
  , minVoltage :: Number
  , worstVoltageBus :: Int
  , severity :: String
  }

type ContingencyReport =
  { caseName :: String
  , loadFactor :: Number
  , totalBranches :: Int
  , criticalCount :: Int
  , warningCount :: Int
  , safeCount :: Int
  , cases :: Array ContingencyCase
  }

-- | Branches worth opening: those in service in the intact network. An
-- | already-open branch has no outage to simulate.
candidateBranches :: Array LineState -> Array LineState
candidateBranches = filter _.inService

-- | Solve the intact case, then one solve per candidate outage.
-- |
-- | Each outage is an independent solve rather than a mutation of shared
-- | state, so the results cannot depend on the order they were run in.
analyse :: Limits -> String -> Number -> Effect ContingencyReport
analyse limits name lf = do
  let spec = baseSpec name lf
  intact <- solve spec
  cases <- traverse (outage spec) (candidateBranches intact.lines)
  let ordered = sortBy bySeverityThenLoading cases
  pure
    { caseName: name
    , loadFactor: lf
    , totalBranches: length cases
    , criticalCount: countLabel Critical ordered
    , warningCount: countLabel Warning ordered
    , safeCount: countLabel Safe ordered
    , cases: ordered
    }
  where
  outage spec line = do
    outcome <- solve (withLinesOut [ line.id ] spec)
    pure (verdict limits line outcome)

  countLabel s = length <<< filter (\c -> c.severity == severityLabel s)

-- | Worst first, and within a severity the heaviest loading first — the order
-- | an operator would want to read them in.
bySeverityThenLoading :: ContingencyCase -> ContingencyCase -> Ordering
bySeverityThenLoading a b =
  case compare (rank a.severity) (rank b.severity) of
    EQ -> compare b.maxLoading a.maxLoading
    other -> other
  where
  rank lbl
    | lbl == severityLabel Critical = 0
    | lbl == severityLabel Warning = 1
    | otherwise = 2

verdict :: Limits -> LineState -> SolveOutcome -> ContingencyCase
verdict limits line outcome =
  { lineId: line.id
  , isTransformer: line.isTransformer
  , converged: outcome.converged
  , maxLoading: loading.loading
  , worstOverloadLine: loading.lineId
  , minVoltage: voltage.voltage
  , worstVoltageBus: voltage.busId
  , severity: severityLabel (classify limits outcome.converged loading.loading voltage.voltage)
  }
  where
  loading = worstLoading outcome.lines
  voltage = worstVoltage outcome.buses
