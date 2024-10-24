{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module OptionPricing where

import Web.Scotty
import Data.Aeson (FromJSON, ToJSON, toJSON, object, (.=))
import Control.Monad (replicateM)
import Control.Monad.IO.Class (liftIO)  -- Import liftIO here
import System.Random (randomRIO)
import Data.Text.Lazy (Text)
import GHC.Generics (Generic)
import Numeric (showFFloat)

-- Define a request structure for option pricing
data OptionRequest = OptionRequest {
    numSims :: Int,    -- Number of simulations
    s       :: Double, -- Underlying price
    k       :: Double, -- Strike price
    r       :: Double, -- Risk-free rate
    v       :: Double, -- Volatility
    t       :: Double  -- Time to maturity
} deriving (Show, Generic)

instance FromJSON OptionRequest
instance ToJSON OptionRequest

-- Gaussian Box-Muller algorithm for generating normal random numbers
gaussianBoxMuller :: IO Double
gaussianBoxMuller = do
  let loop = do
        x <- randomRIO (-1.0, 1.0)
        y <- randomRIO (-1.0, 1.0)
        let euclidSq = x * x + y * y
        if euclidSq >= 1.0
          then loop
          else return $ x * sqrt (-2.0 * log euclidSq / euclidSq)
  loop

-- Heaviside step function
heaviside :: Double -> Double
heaviside val = if val >= 0 then 1.0 else 0.0

-- Monte Carlo method for pricing a digital call option
monteCarloDigitalCallPrice :: Int -> Double -> Double -> Double -> Double -> Double -> IO Double
monteCarloDigitalCallPrice numSims s k r v t = do
  let sAdjust = s * exp (t * (r - 0.5 * v * v))
  payoffs <- replicateM numSims $ do
    gaussBm <- gaussianBoxMuller
    let sCur = sAdjust * exp (sqrt (v * v * t) * gaussBm)
    return $ heaviside (sCur - k)
  let payoffSum = sum payoffs
  return $ (payoffSum / fromIntegral numSims) * exp (-r * t)

-- Monte Carlo method for pricing a digital put option
monteCarloDigitalPutPrice :: Int -> Double -> Double -> Double -> Double -> Double -> IO Double
monteCarloDigitalPutPrice numSims s k r v t = do
  let sAdjust = s * exp (t * (r - 0.5 * v * v))
  payoffs <- replicateM numSims $ do
    gaussBm <- gaussianBoxMuller
    let sCur = sAdjust * exp (sqrt (v * v * t) * gaussBm)
    return $ heaviside (k - sCur)
  let payoffSum = sum payoffs
  return $ (payoffSum / fromIntegral numSims) * exp (-r * t)

-- API endpoint handler for option pricing
handleOptionPricing :: Text -> (Int -> Double -> Double -> Double -> Double -> Double -> IO Double) -> ActionM ()
handleOptionPricing optionType pricingFunction = do
  req <- jsonData :: ActionM OptionRequest
  let OptionRequest numSims s k r v t = req
  price <- liftIO $ pricingFunction numSims s k r v t  -- Now liftIO is in scope
  json $ object [ "optionType" .= optionType
                , "price" .= showFFloat (Just 5) price ""
                , "numSims" .= numSims
                , "underlying" .= s
                , "strike" .= k
                , "riskFreeRate" .= r
                , "volatility" .= v
                , "maturity" .= t ]
