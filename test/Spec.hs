module Main (main) where

import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "Example Test" $ do
    it "should pass" $ do
      True `shouldBe` True
