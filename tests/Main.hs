module Main where

import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "purescript-python" $ do
    it "placeholder test" $ do
      True `shouldBe` True
