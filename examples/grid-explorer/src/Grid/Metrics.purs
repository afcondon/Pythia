-- | Network resilience and topology metrics
module Grid.Metrics
  ( NetworkMetrics
  , calculateMetrics
  ) where

import Prelude
import Effect (Effect)
import Grid.PowerFlow (NetworkData)

-- | Comprehensive network metrics
type NetworkMetrics =
  { -- Topology metrics
    numBuses :: Int
  , numLines :: Int
  , numGenerators :: Int
  , avgDegree :: Number              -- Average connections per bus
  , maxDegree :: Int                 -- Most connected bus
  , diameter :: Int                  -- Graph diameter (longest shortest path)

    -- Power flow metrics
  , totalLoadMw :: Number
  , totalGenMw :: Number
  , totalLossMw :: Number
  , avgLineLoading :: Number
  , maxLineLoading :: Number
  , avgVoltagePu :: Number
  , minVoltagePu :: Number
  , maxVoltagePu :: Number

    -- Resilience metrics
  , connectivityIndex :: Number      -- 0-1 how well connected
  , redundancyRatio :: Number        -- Lines / minimum spanning tree
  , criticalLineCount :: Int         -- Lines whose failure causes issues
  , vulnerabilityScore :: Number     -- 0-1 overall vulnerability
  }

-- | Calculate all metrics for a network
foreign import calculateMetrics :: NetworkData -> Effect NetworkMetrics
