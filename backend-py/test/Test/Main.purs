module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)

-- | backend-py's real test is the differential corpus (`./run_conformance.sh`),
-- | which diffs generated Python against the JS reference byte-for-byte. This
-- | placeholder exists only so `spago test` has an entry point.
main :: Effect Unit
main = log "backend-py: see ./run_conformance.sh for the conformance suite"
