-- | UMAP dimensionality reduction bindings for Python
module Data.UMAP
  ( EmbeddingPoint
  , LabeledPoint
  , LabeledEmbedding
  , UMAPConfig
  , defaultConfig
  , fitTransform
  , projectWithLabels
  , getDemoEmbeddings
  ) where

import Prelude
import Data.Function.Uncurried (Fn5, runFn5, Fn4, runFn4)

-- | A point in 2D embedding space
type EmbeddingPoint =
  { x :: Number
  , y :: Number
  }

-- | A labeled point with high-dimensional vector
type LabeledPoint =
  { label :: String
  , vector :: Array Number
  , category :: String
  }

-- | A labeled point projected to 2D
type LabeledEmbedding =
  { label :: String
  , x :: Number
  , y :: Number
  , category :: String
  }

-- | UMAP configuration
type UMAPConfig =
  { nNeighbors :: Int      -- ^ Local neighborhood size (default 15)
  , minDist :: Number      -- ^ Minimum distance between points (default 0.1)
  , nComponents :: Int     -- ^ Output dimensions (default 2)
  , metric :: String       -- ^ Distance metric (default "euclidean")
  }

-- | Default UMAP configuration
defaultConfig :: UMAPConfig
defaultConfig =
  { nNeighbors: 15
  , minDist: 0.1
  , nComponents: 2
  , metric: "euclidean"
  }

-- | Run UMAP on raw vectors
foreign import fitTransformImpl :: Fn5 (Array (Array Number)) Int Number Int String (Array EmbeddingPoint)

fitTransform :: UMAPConfig -> Array (Array Number) -> Array EmbeddingPoint
fitTransform config vectors =
  runFn5 fitTransformImpl vectors config.nNeighbors config.minDist config.nComponents config.metric

-- | Project labeled data to 2D with UMAP
foreign import projectWithLabelsImpl :: Fn4 (Array LabeledPoint) Int Number String (Array LabeledEmbedding)

projectWithLabels :: UMAPConfig -> Array LabeledPoint -> Array LabeledEmbedding
projectWithLabels config data_ =
  runFn4 projectWithLabelsImpl data_ config.nNeighbors config.minDist config.metric

-- | Get demo word embeddings (synthetic but clustered by category)
foreign import getDemoEmbeddings :: Array LabeledPoint
