-- | UMAP Embedding Explorer Demo
-- | Demonstrates using Python's UMAP library for dimensionality reduction
module Demo.EmbeddingExplorer where

import Prelude
import Effect (Effect)
import Effect.Console (log)
import Server.Flask (createApp, get, jsonify, run, cors)
import Data.UMAP (LabeledEmbedding, LabeledPoint, UMAPConfig, projectWithLabels, getDemoEmbeddings)

-- | API response types
type ProjectionResponse =
  { success :: Boolean
  , data ::
      { points :: Array LabeledEmbedding
      , config :: UMAPConfig
      , categories :: Array String
      }
  , error :: String
  }

-- | Get unique categories from embeddings
foreign import getCategories :: Array LabeledPoint -> Array String

-- | UMAP configuration for word embeddings
wordEmbeddingConfig :: UMAPConfig
wordEmbeddingConfig =
  { nNeighbors: 15
  , minDist: 0.1
  , nComponents: 2
  , metric: "cosine"  -- Cosine similarity works well for embeddings
  }

-- | Main entry point
main :: Effect Unit
main = do
  log "🗺️  UMAP Embedding Explorer"
  log "================================"
  log ""

  app <- createApp "EmbeddingExplorer"
  cors app

  -- Health check
  get app "/" do
    pure $ jsonify
      { message: "UMAP Embedding Explorer API"
      , status: "running"
      , endpoints:
          [ "GET /api/embeddings - Get UMAP projection of word embeddings"
          , "GET /api/config - Get current UMAP configuration"
          ]
      }

  -- Main embedding projection endpoint
  get app "/api/embeddings" do
    log "Processing UMAP projection..."
    let rawEmbeddings = getDemoEmbeddings
    let projected = projectWithLabels wordEmbeddingConfig rawEmbeddings
    let categories = getCategories rawEmbeddings
    log $ "Projected " <> show (140) <> " words to 2D"  -- 7 categories × 20 words
    pure $ jsonify
      { success: true
      , data:
          { points: projected
          , config: wordEmbeddingConfig
          , categories: categories
          }
      , error: ""
      }

  -- Config endpoint
  get app "/api/config" do
    pure $ jsonify
      { nNeighbors: wordEmbeddingConfig.nNeighbors
      , minDist: wordEmbeddingConfig.minDist
      , metric: wordEmbeddingConfig.metric
      }

  log "Routes registered:"
  log "  GET /               - Health check"
  log "  GET /api/embeddings - Get UMAP projection"
  log "  GET /api/config     - Get UMAP config"
  log ""

  run app 8081  -- Different port from DataServer
