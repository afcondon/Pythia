-- | Entry point for the Python lowering: the HTTP surface, and nothing else.
-- |
-- | Every route is a thin arrangement of `Grid.*` calls. If analysis starts
-- | appearing here it has escaped the core.
module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Grid.Cascade (defaultConfig, simulate)
import Grid.Contingency (analyse)
import Grid.Metrics (metrics)
import Grid.Severity (defaultLimits)
import Grid.Solver (baseSpec, solve)
import Server.Flask (createApp, cors, get, getWith, jsonify, post, requestArrayInt, requestNumber, run)

-- | The IEEE 30-bus case, which unlike case14 ships real per-line thermal
-- | ratings — six distinct values rather than one placeholder. Without them no
-- | contingency can ever exceed a limit and the whole analysis reads green.
demoCase :: String
demoCase = "case30"

-- | The demo operating point. case30 is comfortable at 0.7 and has a line over
-- | its rating by 1.0, so the knob has something to show on either side.
demoLoadFactor :: Number
demoLoadFactor = 0.7

main :: Effect Unit
main = do
  log "Grid Explorer — PureScript analysis, pandapower physics"
  log ("  demo: " <> demoCase <> " at load factor " <> show demoLoadFactor)

  app <- createApp "GridExplorer"
  cors app

  get app "/" do
    pure $ jsonify
      { message: "Grid Explorer API"
      , status: "running"
      , demoCase
      , demoLoadFactor
      , endpoints:
          [ "GET  /api/network?loadFactor=      solved network state"
          , "GET  /api/contingency?loadFactor=  N-1 analysis over every branch"
          , "GET  /api/metrics?loadFactor=      topology + loading metrics"
          , "POST /api/simulate                 cascading failure"
          ]
      }

  getWith app "/api/network" \req -> do
    outcome <- solve (baseSpec demoCase (lf req))
    pure $ jsonify { success: true, data: outcome, error: "" }

  getWith app "/api/contingency" \req -> do
    report <- analyse defaultLimits demoCase (lf req)
    pure $ jsonify { success: true, data: report, error: "" }

  getWith app "/api/metrics" \req -> do
    outcome <- solve (baseSpec demoCase (lf req))
    pure $ jsonify { success: true, data: metrics outcome, error: "" }

  post app "/api/simulate" \req -> do
    report <- simulate defaultConfig demoCase (lf req) (requestArrayInt req "initialFailures")
    pure $ jsonify { success: true, data: report, error: "" }

  run app 3033
  where
  lf req = requestNumber req "loadFactor" demoLoadFactor
