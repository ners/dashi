{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Switch where

import Clay hiding (label, name, selected, span_, type_)
import Dashi.Components.Util (ariaRole_)
import Dashi.Components.Widget
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Property (name_, selected_, type_)
import Prelude

data Switch model action = Switch
    { name :: MisoString
    , label :: [View model action]
    , selected :: Bool
    }

instance Widget (Switch model action) model action where
    widget' attrs Switch{..}
        | null label = inputEl
        | otherwise = label_ [] [inputEl, span_ [] label]
      where
        inputEl = input_ $ type_ "checkbox" : ariaRole_ "switch" : name_ name : selected_ selected : attrs
    style =
        input # ariaRole "switch" ? do
            display flex
            flexDirection row
            alignItems center
            let heightEm = 1 :: Number
                widthEm = 1.6 :: Number
                paddingYEm = 0.1 :: Number
                paddingXEm = 0.075 :: Number
                knobSize = heightEm - 2 * paddingYEm
            width $ em widthEm
            height $ em heightEm
            paddingYX (em paddingYEm) (em paddingXEm)
            backgroundColor' Colour.Border
            borderRadiusAll' XLarge
            transition "background-color" (sec 0.15) easeInOut 0
            before & do
                important . content $ stringContent ""
                backgroundColor' Colour.InverseText
                display block
                aspectRatio 1
                height $ pct 100
                borderRadiusAll' XLarge
                transition "margin" (sec 0.075) easeInOut 0
            checked & do
                backgroundColor' Colour.BorderFocused
                before & do
                    "margin-inline-start" ~:: em (widthEm - 2 * paddingXEm - knobSize)
