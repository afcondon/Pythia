-- | Power flow calculation bindings for pandapower
module Grid.PowerFlow
  ( NetworkData
  , Bus
  , Line
  , Generator
  , PowerFlowResult
  , loadNetwork
  , runPowerFlow
  , getNetworkTopology
  ) where

import Prelude
import Effect (Effect)

-- | Bus (node) in the power grid
type Bus =
  { id :: Int
  , name :: String
  , busType :: String        -- "slack", "pv", "pq"
  , voltagePu :: Number      -- Per-unit voltage magnitude
  , angleRad :: Number       -- Voltage angle in radians
  , loadMw :: Number         -- Active power load
  , loadMvar :: Number       -- Reactive power load
  , hasGenerator :: Boolean
  , x :: Number              -- Layout x position
  , y :: Number              -- Layout y position
  }

-- | Transmission line (edge) in the power grid
type Line =
  { id :: Int
  , fromBus :: Int
  , toBus :: Int
  , loadingPercent :: Number   -- Current loading as % of thermal limit
  , maxLoadingMva :: Number    -- Thermal limit
  , inService :: Boolean
  , pFromMw :: Number          -- Active power flow from side
  , qFromMvar :: Number        -- Reactive power flow from side
  }

-- | Generator connected to a bus
type Generator =
  { id :: Int
  , bus :: Int
  , pMw :: Number              -- Active power output
  , qMvar :: Number            -- Reactive power output
  , inService :: Boolean
  , pMaxMw :: Number           -- Maximum capacity
  }

-- | Full network data structure
type NetworkData =
  { name :: String
  , baseMva :: Number
  , buses :: Array Bus
  , lines :: Array Line
  , generators :: Array Generator
  , converged :: Boolean
  }

-- | Result of power flow calculation
type PowerFlowResult =
  { network :: NetworkData
  , totalLoadMw :: Number
  , totalGenMw :: Number
  , totalLossMw :: Number
  }

-- | Load a test case network by name
foreign import loadNetwork :: String -> Effect NetworkData

-- | Run AC power flow calculation
foreign import runPowerFlow :: NetworkData -> Effect PowerFlowResult

-- | Get just the topology (no power flow)
foreign import getNetworkTopology :: String -> Effect NetworkData
