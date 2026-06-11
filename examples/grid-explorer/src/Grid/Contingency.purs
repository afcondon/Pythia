-- | N-1 Contingency analysis for power grids
module Grid.Contingency
  ( ContingencyCase
  , ContingencyResult
  , runContingency
  , runSingleContingency
  ) where

import Prelude
import Effect (Effect)
import Grid.PowerFlow (NetworkData)

-- | Result of a single contingency case
type ContingencyCase =
  { lineId :: Int
  , lineName :: String
  , converged :: Boolean
  , maxLoading :: Number           -- Highest line loading after outage
  , worstOverloadLine :: Int       -- Line with highest loading
  , minVoltage :: Number           -- Lowest bus voltage
  , worstVoltageBus :: Int         -- Bus with lowest voltage
  , severity :: String             -- "safe", "warning", "critical"
  }

-- | Full N-1 contingency analysis result
type ContingencyResult =
  { caseName :: String
  , totalLines :: Int
  , criticalCount :: Int
  , warningCount :: Int
  , safeCount :: Int
  , cases :: Array ContingencyCase
  }

-- | Run N-1 contingency analysis (outage of each line one at a time)
foreign import runContingency :: NetworkData -> Effect ContingencyResult

-- | Run contingency for a single line outage
foreign import runSingleContingency :: NetworkData -> Int -> Effect ContingencyCase
