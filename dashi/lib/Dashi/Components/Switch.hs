{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Switch where

import Clay hiding (Background, checked, label, name, selected, span_, type_)
import Clay qualified hiding (Background)
import Dashi.Components.Util (ariaRole_)
import Dashi.Prelude hiding ((#), (&))
import Dashi.Style.Border (BorderColour (BorderColour, BorderFocusedColour))
import Dashi.Style.Colour (LightDark)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu (Yang))
import Dashi.Style.Util
import Data.Coerce (coerce)
import Data.Vector.Strict qualified as Vector
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Event (onChecked)
import Miso.Html.Property (checked_, name_, type_)

data Foreground = Foreground
    deriving stock (Eq, Bounded, Enum)

instance Token Foreground where
    tokenName Foreground = "switch-foreground"

instance ValueToken Foreground where
    type ValueType Foreground = Uchu
    tokenValue Foreground = Yang

newtype Background = Background Bool
    deriving stock (Eq, Bounded)

allBackgrounds :: Vector Background
allBackgrounds = Background <$> [minBound .. maxBound]

instance Enum Background where
    toEnum = (Vector.!) allBackgrounds
    fromEnum = fromJust . flip Vector.findIndex allBackgrounds . (==)

instance Token Background where
    tokenName (Background checked) = "switch-background" <> bool "" "-checked" checked

instance ValueToken Background where
    type ValueType Background = LightDark Uchu
    tokenValue (Background False) = tokenValue BorderColour
    tokenValue (Background True) = tokenValue BorderFocusedColour

data Switch model action = Switch
    { name :: MisoString
    , label :: [View model action]
    , checked :: Bool
    , onChange :: Bool -> action
    }

instance Widget (Switch model action) model action where
    widget' attrs Switch{..}
        | null label = inputEl
        | otherwise = label_ [] [inputEl, span_ [] label]
      where
        inputEl =
            input_
                $ type_ "checkbox"
                : ariaRole_ "switch"
                : name_ name
                : checked_ checked
                : onChecked (onChange . coerce @Checked)
                : attrs
    style = do
        ":root" ? do
            tokenDecl @Foreground
            tokenDecl @Background
        input # ariaRole "switch" ? do
            fontSize' Large
            display flex
            flexDirection row
            alignItems center
            let heightEm = 0.9 :: Number
                widthEm = 1.6 :: Number
                knobSize = heightEm
            width $ em widthEm
            height $ em heightEm
            backgroundColor' $ Background False
            border (em 0.1) solid transparent
            borderRadiusAll' XLarge
            transition "all" (sec 0.15) easeInOut 0
            before & do
                important . content . stringContent $ ""
                important $ "font-size" -: "inherit"
                top $ unitless 0
                backgroundColor' Foreground
                display block
                aspectRatio 1
                height $ pct 100
                borderRadiusAll' XLarge
                transition "margin" (sec 0.075) easeInOut 0
            Clay.checked & do
                backgroundColor' $ Background True
                before & do
                    "margin-inline-start" ~:: em (widthEm - knobSize)
