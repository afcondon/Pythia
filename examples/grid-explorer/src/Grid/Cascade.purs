-- | Cascading failure simulation for power grids
module Grid.Cascade
  ( CascadeStep
  , CascadeResult
  , CascadeParams
  , simulateCascade
  ) where

import Prelude
import Effect (Effect)
import Grid.PowerFlow (NetworkData)

-- | Parameters for cascade simulation
type CascadeParams =
  { initialFailures :: Array Int    -- Line IDs to fail initially
  , loadingThreshold :: Number      -- % loading that triggers failure (e.g., 100.0)
  , maxIterations :: Int            -- Maximum cascade steps
  }

-- | A single step in the cascade
type CascadeStep =
  { iteration :: Int
  , failedLines :: Array Int        -- Lines that failed this step
  , overloadedLines :: Array Int    -- Lines currently overloaded
  , islandedBuses :: Array Int      -- Buses cut off from slack
  , loadShedMw :: Number            -- Load shed this step
  , totalLoadLostMw :: Number       -- Cumulative load lost
  }

-- | Full cascade simulation result
type CascadeResult =
  { converged :: Boolean
  , steps :: Array CascadeStep
  , finalNetwork :: NetworkData
  , totalLoadLostMw :: Number
  , totalLinesLost :: Int
  , cascadeDepth :: Int             -- Number of iterations before stable
  }

-- | Simulate cascading failure from initial line failures
foreign import simulateCascade :: NetworkData -> CascadeParams -> Effect CascadeResult
