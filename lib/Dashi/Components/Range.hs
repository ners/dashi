{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Range where

import Clay hiding (Background, Color, Value, action, fullWidth, max, size, type_, value, var)
import Dashi.Components.Widget
import Dashi.Style.Colour hiding (Background)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util (backgroundColor', borderRadiusAll', colorToken, (~:), (~::))
import Data.Functor ((<&>))
import Miso
import Miso.Html.Element (input_)
import Miso.Html.Property (max_, min_, step_, type_, value_)
import Prelude hiding (max)

data Background = Background
    deriving stock (Eq, Bounded, Enum)

instance Token Background where
    tokenName Background = "range-background-color"

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Background = tokenValue (Text Default) <&> flip setAlpha 0.15

data Progress = Progress
    deriving stock (Eq, Bounded, Enum)

instance Token Progress where
    tokenName Progress = "range-color"

instance ValueToken Progress where
    type ValueType Progress = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Progress = tokenValue $ Text Default

data Range = Range
    { value :: Int
    , step :: Int
    , min :: Int
    , max :: Int
    }

instance Widget Range model action where
    widget' attrs Range{..} =
        input_ $ type_ "range" : value_ (toMisoString value) : step_ (toMisoString step) : min_ (toMisoString min) : max_ (toMisoString max) : attrs
    style = do
        ":root" ? do
            tokenDecl @Background
            tokenDecl @Progress
        input # ("type" @= "range") ? do
            borderRadiusAll' Large
            backgroundColor' Background
            "accent-color" ~:: colorToken Progress
            height $ em 0.5
            "::-webkit-slider-thumb" & do
                "-webkit-appearance" ~: none
                width $ em 1
                height $ em 1
                borderRadiusAll' Large
                cursor ewResize
                backgroundColor' Progress
                marginTop $ em 0.03
