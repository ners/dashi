{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Checkbox where

import Clay hiding (Color, fullWidth, label, legend, name, option, selected, span_, type_)
import Clay qualified
import Dashi.Components.Icon (iconContent, iconFont)
import Dashi.Components.Util (ariaRole_)
import Dashi.Prelude hiding (has, (#), (&), (|>))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Coerce (coerce)
import GHC.IsList (fromList)
import Miso.Html.Element (fieldset_, input_, label_, span_)
import Miso.Html.Event qualified as Html
import Miso.Html.Property (checked_, name_, type_)
import Web.Font.MDI (MDI (MdiCheckboxBlankOutline, MdiCheckboxMarked))

data Checkbox model action = Checkbox
    { name :: MisoString
    , label :: [View model action]
    , selected :: Bool
    , onChecked :: Bool -> action
    }

instance Widget (Checkbox model action) model action where
    widget' attrs Checkbox{..} =
        label_
            []
            [ input_ $ type_ "checkbox" : name_ name : Html.onChecked (onChecked . coerce) : checked_ selected : attrs
            , span_ [] label
            ]
    style = do
        let checkboxOrRadio = input # isOneOf ["type" @= "checkbox", "type" @= "radio"]
        checkboxOrRadio ? do
            pressable
            iconFont
            color' Colour.Border
            checked & color' Colour.BorderFocused
        Clay.label # has (self |> checkboxOrRadio) ? do
            pressable
            display flex
            flexDirection row
            alignItems center
            columnGap' XSmall
            width maxContent
        input # ("type" @= "checkbox") ? do
            borderRadiusAll' XSmall
            before & content (iconContent MdiCheckboxBlankOutline)
            checked <> before & content (iconContent MdiCheckboxMarked)

data CheckboxGroup o model action = CheckboxGroup
    { name :: MisoString
    , options :: [o]
    , label :: o -> [View model action]
    , selected :: o -> Bool
    , onChecked :: o -> Bool -> action
    }

instance (Eq a) => Widget (CheckboxGroup a model action) model action where
    widget' attrs CheckboxGroup{..} =
        fieldset_ [ariaRole_ "group"]
            $ options
            <&> \o ->
                widget'
                    attrs
                    Checkbox
                        { name
                        , label = label o
                        , selected = selected o
                        , onChecked = onChecked o
                        }

    style = do
        sconcat ((self #) . ariaRole <$> fromList ["group", "radiogroup"]) ? do
            display flex
            flexDirection column
            rowGap' XSmall
