-- | Grid Explorer API Server
-- | Flask backend for power grid cascading failure visualization
module Main where

import Prelude
import Effect (Effect)
import Effect.Console (log)
import Server.Flask (createApp, get, post, jsonify, run, cors, getRequestJson)
import Grid.PowerFlow (loadNetwork, runPowerFlow, NetworkData)
import Grid.Cascade (simulateCascade, CascadeResult)
import Grid.Contingency (runContingency, ContingencyResult)
import Grid.Metrics (calculateMetrics, NetworkMetrics)
import Data.Maybe (Maybe(..))

-- | Default test case
defaultNetwork :: String
defaultNetwork = "case14"

-- | Main entry point
main :: Effect Unit
main = do
  log "================================================"
  log "  Grid Explorer API Server"
  log "  PureScript + Python + pandapower"
  log "================================================"
  log ""

  app <- createApp "GridExplorer"
  cors app

  -- Health check / API info
  get app "/" do
    pure $ jsonify
      { message: "Grid Explorer API"
      , status: "running"
      , endpoints:
          [ "GET /api/network - Get network topology"
          , "GET /api/network/:case - Get specific test case (case14, case30, case118)"
          , "GET /api/contingency - Run N-1 contingency analysis"
          , "POST /api/simulate - Simulate cascading failure"
          , "GET /api/metrics - Get network resilience metrics"
          ]
      }

  -- Get network topology
  get app "/api/network" do
    log $ "Loading network: " <> defaultNetwork
    network <- loadNetwork defaultNetwork
    powerFlow <- runPowerFlow network
    pure $ jsonify
      { success: true
      , data: powerFlow
      , error: ""
      }

  -- N-1 Contingency analysis
  get app "/api/contingency" do
    log "Running N-1 contingency analysis..."
    network <- loadNetwork defaultNetwork
    results <- runContingency network
    log "Contingency analysis complete"
    pure $ jsonify
      { success: true
      , data: results
      , error: ""
      }

  -- Simulate cascading failure
  post app "/api/simulate" \req -> do
    log "Simulating cascading failure..."
    params <- getRequestJson req
    network <- loadNetwork defaultNetwork
    cascade <- simulateCascade network params
    log "Cascade simulation complete"
    pure $ jsonify
      { success: true
      , data: cascade
      , error: ""
      }

  -- Network metrics
  get app "/api/metrics" do
    log "Calculating network metrics..."
    network <- loadNetwork defaultNetwork
    metrics <- calculateMetrics network
    pure $ jsonify
      { success: true
      , data: metrics
      , error: ""
      }

  log "Routes registered:"
  log "  GET  /               - Health check"
  log "  GET  /api/network    - Get network topology"
  log "  GET  /api/contingency - N-1 contingency analysis"
  log "  POST /api/simulate   - Cascade simulation"
  log "  GET  /api/metrics    - Network metrics"
  log ""
  log "Starting server on http://localhost:8082"

  run app 8082
