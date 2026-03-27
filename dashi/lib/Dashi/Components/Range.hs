{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Range where

import Clay hiding
    ( Background
    , Color
    , Value
    , action
    , clamp
    , div
    , fullWidth
    , max
    , rem
    , round
    , size
    , type_
    , value
    , var
    )
import Dashi.Prelude hiding (max, none, (#))
import Dashi.Style.Colour
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu (..))
import Dashi.Style.Util
import Data.Ord (clamp)
import Miso.CSS (styleInline_)
import Miso.Html.Element (input_)
import Miso.Html.Event qualified as Html
import Miso.Html.Property (max_, min_, step_, type_, value_)

data Background = Background
    deriving stock (Eq, Bounded, Enum)

instance Token Background where
    tokenName Background = "range-background-color"

instance ValueToken Background where
    type ValueType Background = LightDark Uchu
    tokenValue Background = LightDark Yin2 Yin8

data Thumb = Thumb
    deriving stock (Eq, Bounded, Enum)

instance Token Thumb where
    tokenName Thumb = "range-thumb-color"

instance ValueToken Thumb where
    type ValueType Thumb = LightDark Uchu
    tokenValue Thumb = LightDark Yin9 Yin1

data Progress = Progress
    deriving stock (Eq, Bounded, Enum)

instance Token Progress where
    tokenName Progress = "range-progress-color"

instance ValueToken Progress where
    type ValueType Progress = LightDark Uchu
    tokenValue Progress = LightDark Yin6 Yin4

data Range action = Range
    { value :: Int
    , step :: Int
    , min :: Int
    , max :: Int
    , onChange :: Int -> action
    }

instance Widget (Range action) model action where
    widget' attrs Range{..} =
        input_
            $ type_ "range"
            : min_ (toMisoString roundedDownMinValue)
            : max_ (toMisoString roundedUpMaxValue)
            : step_ (toMisoString step)
            : value_ (toMisoString displayValue)
            : styleInline_ ("--progress:" <> toMisoString roundedPercentage <> "%")
            : Html.onInput (onChange . clamp (min, max) . fromMisoString)
            : attrs
      where
        roundedDownMinValue
            | min `rem` step == 0 = min
            | otherwise = (min `div` step - 1) * step

        roundedUpMaxValue
            | max `rem` step == 0 = max
            | otherwise = (max `div` step + 1) * step

        displayValue =
            let maxSliderValue = (max `div` step) * step
                minSliderValue = ceiling @Milli (fromIntegral min / fromIntegral step) * step
             in if value < minSliderValue
                    then roundedDownMinValue
                    else
                        if value > maxSliderValue
                            then roundedUpMaxValue
                            else value
        roundedPercentage
            | min >= max = 0 :: Milli
            | otherwise =
                let range = roundedUpMaxValue - roundedDownMinValue
                    relativeValue = displayValue - roundedDownMinValue
                    numSteps = round @Milli $ fromIntegral relativeValue / fromIntegral step
                 in fromIntegral (numSteps * step) / fromIntegral range * 100
    style = do
        ":root" ? do
            tokenDecl @Background
            tokenDecl @Progress
            tokenDecl @Thumb
        input # ("type" @= "range") ? do
            borderRadiusAll' Large
            backgroundColor' Background
            "accent-color" ~:: colorToken Thumb
            height $ em 0.5
            color' Progress
            cursor ewResize
            "background-image"
                -: "linear-gradient(to right, currentColor var(--progress), transparent var(--progress))"
        sconcat
            ( (input # ("type" @= "range") #)
                <$> ["::-moz-range-thumb", "::-webkit-slider-thumb"]
            )
            ? do
                "-moz-appearance" ~: none
                "-webkit-appearance" ~: none
                width $ em 1
                height $ em 1
                borderRadiusAll' Large
                backgroundColor' Thumb
                marginTop $ em 0.03
                borderWidth nil
