{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Range where

import Clay hiding (Background, Color, Value, action, clamp, div, fullWidth, max, rem, round, size, type_, value, var)
import Dashi.Components.Widget
import Dashi.Style.Colour hiding (Background)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util (backgroundColor', borderRadiusAll', color', colorToken, (~:), (~::))
import Data.Functor ((<&>))
import Data.Ord (clamp)
import Miso
import Miso.CSS (styleInline_)
import Miso.Html.Element (input_)
import Miso.Html.Event qualified as Miso
import Miso.Html.Property (max_, min_, step_, type_, value_)
import Prelude hiding (max)

data Background = Background
    deriving stock (Eq, Bounded, Enum)

instance Token Background where
    tokenName Background = "range-background-color"

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Background = tokenValue (Text Default) <&> flip setAlpha 0.15

data Thumb = Thumb
    deriving stock (Eq, Bounded, Enum)

instance Token Thumb where
    tokenName Thumb = "range-thumb-color"

instance ValueToken Thumb where
    type ValueType Thumb = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Thumb = tokenValue $ Text Default

data Progress = Progress
    deriving stock (Eq, Bounded, Enum)

instance Token Progress where
    tokenName Progress = "range-progress-color"

instance ValueToken Progress where
    type ValueType Progress = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Progress = tokenValue (Text Default) <&> flip setAlpha 0.5

data Range action = Range
    { value :: Int
    , step :: Int
    , min :: Int
    , max :: Int
    , onChange :: Int -> action
    }

instance Widget (Range action) model action where
    widget' attrs Range{..} =
        input_ $
            type_ "range"
                : Miso.onInput (onChange . clamp (min, max) . fromMisoString)
                : step_ (toMisoString step)
                : value_ (toMisoString displayValue)
                : min_ (toMisoString roundedDownMinValue)
                : max_ (toMisoString roundedUpMaxValue)
                : styleInline_ ("--progress:" <> toMisoString roundedPercentage <> "%")
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
                minSliderValue = ceiling @Double (fromIntegral min / fromIntegral step) * step
             in if value < minSliderValue
                    then roundedDownMinValue
                    else
                        if value > maxSliderValue
                            then roundedUpMaxValue
                            else value
        roundedPercentage
            | min >= max = 0 :: Double
            | otherwise =
                let range = roundedUpMaxValue - roundedDownMinValue
                    relativeValue = displayValue - roundedDownMinValue
                    numSteps = round @Double $ fromIntegral relativeValue / fromIntegral step
                    rounded = numSteps * step
                 in fromIntegral rounded / fromIntegral range * 100
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
            "background-image" -: "linear-gradient(to right, currentColor var(--progress), transparent var(--progress))"
            "::-webkit-slider-thumb" & do
                "-webkit-appearance" ~: none
                width $ em 1
                height $ em 1
                borderRadiusAll' Large
                cursor ewResize
                backgroundColor' Thumb
                marginTop $ em 0.03
