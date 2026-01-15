{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Switch where

import Clay hiding (checked, label, name, selected, span_, type_)
import Clay qualified
import Dashi.Components.Util (ariaRole_)
import Dashi.Prelude hiding ((#), (&))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Coerce (coerce)
import Miso.Event.Types (Checked (..))
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Event (onChecked)
import Miso.Html.Property (checked_, name_, type_)

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
    style =
        input # ariaRole "switch" ? do
            display flex
            flexDirection row
            alignItems center
            let heightEm = 0.9 :: Number
                widthEm = 1.6 :: Number
                knobSize = heightEm
            width $ em widthEm
            height $ em heightEm
            backgroundColor' Colour.Border
            border (em 0.1) solid transparent
            borderRadiusAll' XLarge
            transition "all" (sec 0.15) easeInOut 0
            before & do
                important . content $ stringContent ""
                backgroundColor' Colour.InverseText
                display block
                aspectRatio 1
                height $ pct 100
                borderRadiusAll' XLarge
                transition "margin" (sec 0.075) easeInOut 0
            Clay.checked & do
                backgroundColor' Colour.BorderFocused
                before & do
                    "margin-inline-start" ~:: em (widthEm - knobSize)
