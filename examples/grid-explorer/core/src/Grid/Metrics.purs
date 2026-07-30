-- | Topology and loading metrics.
-- |
-- | All of this was networkx and numpy in `Grid_Metrics_foreign.py`. Degree,
-- | diameter and connectivity over a thirty-node graph are not domain
-- | expertise borrowed from a library — they are arithmetic on our own data,
-- | so they belong in the core.
module Grid.Metrics
  ( TopologyMetrics
  , LoadingMetrics
  , NetworkMetrics
  , topology
  , loading
  , metrics
  ) where

import Prelude

import Data.Array (filter, index, length, sort)
import Data.Foldable (maximum, sum)
import Data.Int (toNumber)
import Data.Maybe (fromMaybe)
import Grid.Graph (adjacencyFrom, components, degrees, diameter)
import Grid.Types (SolveOutcome, branchEndpoints, inServiceLines)

type TopologyMetrics =
  { busCount :: Int
  , branchCount :: Int
  , generatorCount :: Int
  , averageDegree :: Number
  , maxDegree :: Int
  , diameter :: Int
  , componentCount :: Int
  , isConnected :: Boolean
  }

type LoadingMetrics =
  { maxLoadingPercent :: Number
  , meanLoadingPercent :: Number
  , medianLoadingPercent :: Number
  , overloadedCount :: Int
  , totalLoadMw :: Number
  , totalGenMw :: Number
  , totalLossMw :: Number
  , lossPercent :: Number
  }

type NetworkMetrics =
  { caseName :: String
  , topology :: TopologyMetrics
  , loading :: LoadingMetrics
  }

topology :: SolveOutcome -> TopologyMetrics
topology outcome =
  { busCount: length busIds
  , branchCount: length live
  , generatorCount: length (filter _.inService outcome.generators)
  , averageDegree: mean (map toNumber ds)
  , maxDegree: fromMaybe 0 (maximum ds)
  , diameter: diameter adjacency busIds
  , componentCount: comps
  , isConnected: comps <= 1
  }
  where
  busIds = map _.id outcome.buses
  live = inServiceLines outcome.lines
  adjacency = adjacencyFrom busIds (branchEndpoints outcome.lines)
  ds = degrees adjacency
  comps = length (components adjacency busIds)

loading :: SolveOutcome -> LoadingMetrics
loading outcome =
  { maxLoadingPercent: fromMaybe 0.0 (maximum loadings)
  , meanLoadingPercent: mean loadings
  , medianLoadingPercent: median loadings
  , overloadedCount: length (filter (_ > 100.0) loadings)
  , totalLoadMw: outcome.totalLoadMw
  , totalGenMw: outcome.totalGenMw
  , totalLossMw: outcome.totalLossMw
  , lossPercent:
      if outcome.totalGenMw > 0.0 then outcome.totalLossMw / outcome.totalGenMw * 100.0
      else 0.0
  }
  where
  loadings = map _.loadingPercent (inServiceLines outcome.lines)

metrics :: SolveOutcome -> NetworkMetrics
metrics outcome =
  { caseName: outcome.name
  , topology: topology outcome
  , loading: loading outcome
  }

mean :: Array Number -> Number
mean xs
  | length xs == 0 = 0.0
  | otherwise = sum xs / toNumber (length xs)

-- | Mean of the two middle values on an even count, so the figure is stable
-- | rather than biased low.
median :: Array Number -> Number
median xs = case length xs of
  0 -> 0.0
  n ->
    let
      sorted = sort xs
      mid = n / 2
    in
      if n `mod` 2 == 1 then at sorted mid
      else (at sorted (mid - 1) + at sorted mid) / 2.0
  where
  at arr i = fromMaybe 0.0 (index arr i)
