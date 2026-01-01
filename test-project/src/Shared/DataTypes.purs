-- | Shared data types for client-server communication
-- | This module compiles to both Python (backend) and JavaScript (frontend)
module Shared.DataTypes where

import Prelude

-- | A single data point for visualization
type DataPoint =
  { x :: Number
  , y :: Number
  , label :: String
  }

-- | A dataset is an array of data points
type Dataset = Array DataPoint

-- | Time series data point
type TimeSeriesPoint =
  { timestamp :: String  -- ISO format
  , value :: Number
  , series :: String
  }

type TimeSeries = Array TimeSeriesPoint

-- | Statistical summary
type Stats =
  { mean :: Number
  , median :: Number
  , stdDev :: Number
  , min :: Number
  , max :: Number
  , count :: Int
  }

-- | API response wrapper
type ApiResponse a =
  { success :: Boolean
  , data :: a
  , error :: String  -- empty if success
  }

-- | Helper to create success response
success :: forall a. a -> ApiResponse a
success d = { success: true, data: d, error: "" }

-- | Helper to create error response
failure :: forall a. a -> String -> ApiResponse a
failure d msg = { success: false, data: d, error: msg }

-- | Chart configuration
type ChartConfig =
  { title :: String
  , xLabel :: String
  , yLabel :: String
  , width :: Int
  , height :: Int
  }

defaultChartConfig :: ChartConfig
defaultChartConfig =
  { title: "Chart"
  , xLabel: "X"
  , yLabel: "Y"
  , width: 800
  , height: 600
  }
