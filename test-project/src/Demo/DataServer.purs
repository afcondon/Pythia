-- | Demo: PureScript server providing data for browser visualization
module Demo.DataServer where

import Prelude
import Effect (Effect)
import Effect.Console (log)
import Server.Flask (Flask, Response, createApp, get, cors, run, jsonify)
import Shared.DataTypes (DataPoint, Dataset, Stats, success)

-- | Generate sample sine wave data
foreign import generateSineData :: Int -> Dataset

-- | Generate random scatter data
foreign import generateScatterData :: Int -> Dataset

-- | Compute statistics for a dataset
foreign import computeDatasetStats :: Dataset -> Stats

-- | Main server entry point
main :: Effect Unit
main = do
  log "Starting PurePy Data Server..."
  log ""

  app <- createApp "DataServer"
  cors app  -- Enable CORS for browser access

  -- Health check endpoint
  get app "/" do
    pure $ jsonify { message: "PurePy Data Server", status: "running" }

  -- Sine wave data endpoint
  get app "/api/sine" do
    let dataset = generateSineData 100
    let stats = computeDatasetStats dataset
    pure $ jsonify $ success { points: dataset, stats: stats }

  -- Scatter plot data endpoint
  get app "/api/scatter" do
    let dataset = generateScatterData 50
    let stats = computeDatasetStats dataset
    pure $ jsonify $ success { points: dataset, stats: stats }

  -- Configurable data endpoint
  get app "/api/data/:type/:count" do
    -- For now, return sine data (would parse params in real impl)
    let dataset = generateSineData 100
    pure $ jsonify $ success { points: dataset }

  log "Routes registered:"
  log "  GET /           - Health check"
  log "  GET /api/sine   - Sine wave data (100 points)"
  log "  GET /api/scatter - Random scatter data (50 points)"
  log ""

  run app 8080
