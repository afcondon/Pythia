-- | Cascading failure: trip what is overloaded, re-solve, repeat.
-- |
-- | The propagation rule is the exhibit's actual subject, so it is stated here
-- | rather than buried in a Python loop. Each round re-solves from scratch with
-- | the accumulated outage set, which keeps every step reproducible on its own.
module Grid.Cascade
  ( CascadeConfig
  , CascadeStep
  , CascadeReport
  , defaultConfig
  , simulate
  ) where

import Prelude

import Data.Array (elem, filter, length, nub, snoc)
import Data.Foldable (sum)
import Effect (Effect)
import Grid.Graph (adjacencyFrom, islandedBuses)
import Grid.Solver (baseSpec, solve, withLinesOut, withLoadsOut)
import Grid.Types (BusState, LineState, SolveOutcome, branchEndpoints, inServiceLines)

type CascadeConfig =
  { loadingThresholdPercent :: Number
  , maxRounds :: Int
  }

-- | Trip at the thermal rating, and stop after ten rounds — enough for any
-- | cascade on a thirty-bus network to either settle or take the grid down.
defaultConfig :: CascadeConfig
defaultConfig =
  { loadingThresholdPercent: 100.0
  , maxRounds: 10
  }

type CascadeStep =
  { round :: Int
  , overloadedLines :: Array Int
  , trippedLines :: Array Int
  , islandedBuses :: Array Int
  , loadShedMw :: Number
  , cumulativeLoadLostMw :: Number
  }

type CascadeReport =
  { caseName :: String
  , loadFactor :: Number
  , converged :: Boolean
  , initialFailures :: Array Int
  , steps :: Array CascadeStep
  , totalLoadLostMw :: Number
  , totalLinesLost :: Int
  , cascadeDepth :: Int
  , finalNetwork :: SolveOutcome
  }

-- | Seed the network with an initial outage set and let it propagate.
-- |
-- | A round trips every in-service branch over the threshold, then sheds the
-- | load on any bus the trips have cut off from a slack bus. It stops when a
-- | round changes nothing, the solve stops converging, or `maxRounds` is hit.
simulate :: CascadeConfig -> String -> Number -> Array Int -> Effect CascadeReport
simulate config name lf initial = do
  let spec = baseSpec name lf
  first <- solve (withLinesOut initial spec)
  result <- go spec 0 (nub initial) [] [] 0.0 first
  pure
    { caseName: name
    , loadFactor: lf
    , converged: result.outcome.converged
    , initialFailures: initial
    , steps: result.steps
    , totalLoadLostMw: result.lost
    , totalLinesLost: length result.out - length initial
    , cascadeDepth: length result.steps
    , finalNetwork: result.outcome
    }
  where
  go spec round out shedBuses steps lost outcome
    | round >= config.maxRounds = pure { out, steps, lost, outcome }
    | not outcome.converged = pure { out, steps, lost, outcome }
    | otherwise = do
        let
          overloaded = overloadedIds config outcome.lines
          tripped = filter (\i -> not (elem i out)) overloaded
          islanded = filter (\b -> not (elem b shedBuses))
            (islandsAfter outcome (out <> tripped))
          shed = sum (map _.loadMw (busesWithIds outcome.buses islanded))
        if length tripped == 0 && length islanded == 0 then
          pure { out, steps, lost, outcome }
        else do
          let
            out' = out <> tripped
            shedBuses' = shedBuses <> islanded
            lost' = lost + shed
            step =
              { round
              , overloadedLines: overloaded
              , trippedLines: tripped
              , islandedBuses: islanded
              , loadShedMw: shed
              , cumulativeLoadLostMw: lost'
              }
          next <- solve (withLoadsOut shedBuses' (withLinesOut out' spec))
          go spec (round + 1) out' shedBuses' (snoc steps step) lost' next

-- | Branches carrying a defined flow that is past the trip threshold.
-- |
-- | The `energised` half of that (via `inServiceLines`) is load-bearing, and
-- | its absence was a real and visible bug: once a round islands part of the
-- | network, the closed branches inside the island report NaN loading, and
-- | `nan > 100.0` is `true` in PureScript — `Ord Number` is `unsafeCompare`,
-- | which answers `GT` for anything it cannot order. Every de-energised
-- | branch therefore looked overloaded and was tripped, turning a
-- | three-branch outage into a seven-branch one. The exhibit's README
-- | documented the wrong number as a feature for months.
overloadedIds :: CascadeConfig -> Array LineState -> Array Int
overloadedIds config =
  map _.id <<< filter (\l -> l.loadingPercent > config.loadingThresholdPercent)
    <<< inServiceLines

-- | Buses left with no path to a slack bus once `out` is open.
islandsAfter :: SolveOutcome -> Array Int -> Array Int
islandsAfter outcome out =
  islandedBuses adjacency slackBuses (map _.id outcome.buses)
  where
  surviving = filter (\l -> not (elem l.id out)) outcome.lines
  adjacency = adjacencyFrom (map _.id outcome.buses) (branchEndpoints surviving)
  slackBuses = map _.id (filter (\b -> b.busType == "slack") outcome.buses)

busesWithIds :: Array BusState -> Array Int -> Array BusState
busesWithIds buses ids = filter (\b -> elem b.id ids) buses
