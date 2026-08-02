-- | Classification of a solved network state.
-- |
-- | This is the judgement the exhibit is really making, so it belongs here and
-- | not behind a `foreign import`. It used to be `_classify_severity` in
-- | `Grid_Contingency_foreign.py`, returning a String.
module Grid.Severity
  ( Limits
  , defaultLimits
  , classify
  , worstLoading
  , worstVoltage
  ) where

import Prelude

import Data.Array (filter)
import Data.Foldable (foldl)
import Grid.Types (LineState, BusState, Severity(..), inServiceLines)

-- | The thresholds a planner would argue about, in one record rather than
-- | scattered through the classifier.
-- |
-- | Loadings are percentages of thermal rating; voltages are per-unit.
type Limits =
  { criticalLoadingPercent :: Number
  , warningLoadingPercent :: Number
  , criticalVoltagePu :: Number
  , warningVoltagePu :: Number
  }

-- | Standard planning limits: 100 % of thermal rating, and the ±5 %/±10 %
-- | voltage band.
defaultLimits :: Limits
defaultLimits =
  { criticalLoadingPercent: 100.0
  , warningLoadingPercent: 80.0
  , criticalVoltagePu: 0.90
  , warningVoltagePu: 0.95
  }

-- | A non-convergent solve is critical: the network has no steady state, which
-- | is worse than any particular overload, not better.
classify :: Limits -> Boolean -> Number -> Number -> Severity
classify limits converged maxLoading minVoltage
  | not converged = Critical
  | maxLoading > limits.criticalLoadingPercent = Critical
  | minVoltage < limits.criticalVoltagePu = Critical
  | maxLoading > limits.warningLoadingPercent = Warning
  | minVoltage < limits.warningVoltagePu = Warning
  | otherwise = Safe

-- | Heaviest loading among branches carrying a defined flow, with the branch
-- | that carries it. Out-of-service branches report 0 % and would otherwise
-- | look healthy; de-energised ones have no loading at all (`inServiceLines`).
worstLoading :: Array LineState -> { loading :: Number, lineId :: Int }
worstLoading lines =
  foldl step { loading: 0.0, lineId: -1 } (inServiceLines lines)
  where
  step acc l =
    if l.loadingPercent > acc.loading then { loading: l.loadingPercent, lineId: l.id }
    else acc

-- | Lowest voltage among energised buses, with the bus. Seeded above any
-- | plausible per-unit value so the first bus always wins.
-- |
-- | An islanded bus has no voltage. Filtering rather than relying on the
-- | comparison is deliberate: a NaN would survive `<` here by accident, and
-- | the same accident in the other direction is what the `>` in `worstLoading`
-- | and in the cascade's trip test got wrong. See `Grid.Types.LineState`.
worstVoltage :: Array BusState -> { voltage :: Number, busId :: Int }
worstVoltage buses =
  foldl step { voltage: 2.0, busId: -1 } (filter _.energised buses)
  where
  step acc b =
    if b.voltagePu < acc.voltage then { voltage: b.voltagePu, busId: b.id }
    else acc
