-- | Test module for Python FFI
module FFITest where

-- | Foreign function to add two numbers (implemented in Python)
foreign import pyAdd :: Int -> Int -> Int

-- | Foreign function to multiply two numbers
foreign import pyMul :: Int -> Int -> Int

-- | Foreign function that uses Python's math library
foreign import pySqrt :: Number -> Number

-- | Use the foreign functions
testFFI :: Int
testFFI = pyAdd 10 (pyMul 3 4)

-- | Test sqrt
testSqrt :: Number
testSqrt = pySqrt 16.0
