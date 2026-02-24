module Test.CrossBackend.Numbers where

import Prelude

import Data.Int (toNumber, fromNumber, floor, round, toStringAs, decimal, hexadecimal, binary)
import Data.Int.Bits (and, or, xor, shl, shr, complement)
import Data.Maybe (Maybe(..))
import Data.Number as N
import Effect (Effect)
import Effect.Console (log)

-- | Cross-backend number tests.
-- | Each test prints "TEST <name>: <value>" for comparison between JS and Python.
main :: Effect Unit
main = do
  log "=== CrossBackend.Numbers ==="

  -- Integer arithmetic
  log $ "TEST int-add: " <> show (1 + 2 :: Int)
  log $ "TEST int-mul: " <> show (6 * 7 :: Int)
  log $ "TEST int-sub: " <> show (10 - 3 :: Int)
  log $ "TEST int-div: " <> show (10 / 3 :: Int)
  log $ "TEST int-mod: " <> show (mod 10 3)
  log $ "TEST int-negate: " <> show (negate 42 :: Int)

  -- Int edge cases
  log $ "TEST int-max: " <> show (top :: Int)
  log $ "TEST int-min: " <> show (bottom :: Int)

  -- Float arithmetic
  log $ "TEST num-add: " <> show (1.5 + 2.5 :: Number)
  log $ "TEST num-mul: " <> show (3.0 * 4.0 :: Number)
  log $ "TEST num-div: " <> show (10.0 / 3.0 :: Number)

  -- Float formatting (potential divergence)
  log $ "TEST num-show-int: " <> show (42.0 :: Number)
  log $ "TEST num-show-frac: " <> show (3.14 :: Number)
  log $ "TEST num-show-small: " <> show (0.001 :: Number)
  log $ "TEST num-show-large: " <> show (1.0e10 :: Number)
  log $ "TEST num-show-neg: " <> show (-0.5 :: Number)

  -- Special values
  log $ "TEST nan-isNaN: " <> show (N.isNaN N.nan)
  log $ "TEST inf-isFinite: " <> show (N.isFinite N.infinity)
  log $ "TEST num-isFinite: " <> show (N.isFinite 42.0)

  -- Int conversion
  log $ "TEST toNumber: " <> show (toNumber 42)
  log $ "TEST fromNumber-int: " <> show (fromNumber 42.0)
  log $ "TEST fromNumber-frac: " <> show (fromNumber 3.14)

  -- Int base conversion
  log $ "TEST toStringAs-dec: " <> show (toStringAs decimal 42)
  log $ "TEST toStringAs-hex: " <> show (toStringAs hexadecimal 255)
  log $ "TEST toStringAs-bin: " <> show (toStringAs binary 10)

  -- Bitwise operations
  log $ "TEST bit-and: " <> show (and 5 3)
  log $ "TEST bit-or: " <> show (or 5 3)
  log $ "TEST bit-xor: " <> show (xor 5 3)
  log $ "TEST bit-shl: " <> show (shl 1 4)
  log $ "TEST bit-shr: " <> show (shr 16 2)
  log $ "TEST bit-complement: " <> show (complement 0)

  -- Math functions
  log $ "TEST floor: " <> show (N.floor 3.7)
  log $ "TEST ceil: " <> show (N.ceil 3.2)
  log $ "TEST abs: " <> show (N.abs (-5.0))
  log $ "TEST sign-pos: " <> show (N.sign 5.0)
  log $ "TEST sign-neg: " <> show (N.sign (-5.0))
  log $ "TEST sign-zero: " <> show (N.sign 0.0)
  log $ "TEST trunc: " <> show (N.trunc 3.7)
  log $ "TEST trunc-neg: " <> show (N.trunc (-3.7))

  -- Boolean
  log $ "TEST bool-and: " <> show (true && false)
  log $ "TEST bool-or: " <> show (true || false)
  log $ "TEST bool-not: " <> show (not true)

  log "=== Done ==="
