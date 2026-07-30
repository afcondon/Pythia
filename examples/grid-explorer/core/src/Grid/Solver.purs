-- | The seam.
-- |
-- | This is the only module in `core/` that carries a `foreign import`, and it
-- | declares exactly one operation: solve a named IEEE case, at a load factor,
-- | with a given set of branches and loads out of service.
-- |
-- | Everything a power engineer would call expertise — Newton-Raphson AC power
-- | flow — is behind this call, in pandapower. Everything that is *our*
-- | analysis — which branches to open, what counts as a violation, how a
-- | cascade propagates, what the topology metrics are — is in the FFI-free
-- | modules alongside, expressed in PureScript.
-- |
-- | The spec is deliberately self-contained: no mutable network handle crosses
-- | the boundary, so calls are independent and can be issued in any order.
module Grid.Solver
  ( solve
  , baseSpec
  , withLinesOut
  , withLoadsOut
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Grid.Types (SolveOutcome, SolveSpec)

foreign import solveImpl :: EffectFn1 SolveSpec SolveOutcome

-- | Run one AC power flow.
solve :: SolveSpec -> Effect SolveOutcome
solve = runEffectFn1 solveImpl

-- | The intact network at a given load factor.
baseSpec :: String -> Number -> SolveSpec
baseSpec name lf =
  { caseName: name
  , loadFactor: lf
  , linesOut: []
  , loadsOut: []
  }

withLinesOut :: Array Int -> SolveSpec -> SolveSpec
withLinesOut ids spec = spec { linesOut = ids }

withLoadsOut :: Array Int -> SolveSpec -> SolveSpec
withLoadsOut ids spec = spec { loadsOut = ids }
