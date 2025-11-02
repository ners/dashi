{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Checkbox where

import Clay hiding (fullWidth, label, legend, name, option, selected, span_, type_)
import Clay qualified
import Dashi.Components.Icon (iconContent, iconFont)
import Dashi.Components.Util (ariaRole_)
import Dashi.Components.Widget
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Data.Functor ((<&>))
import Data.Semigroup (sconcat)
import GHC.IsList (fromList)
import Miso (MisoString, View)
import Miso.Html.Element (fieldset_, input_, label_, span_)
import Miso.Html.Property (name_, selected_, type_)
import Web.Font.MDI (MDI (MdiCheckboxBlankOutline, MdiCheckboxMarked))
import Prelude

data Checkbox model action = Checkbox
    { name :: MisoString
    , label :: [View model action]
    , selected :: Bool
    }

instance Widget (Checkbox model action) model action where
    widget' attrs Checkbox{..} =
        label_
            []
            [ input_ $ type_ "checkbox" : name_ name : selected_ selected : attrs
            , span_ [] label
            ]
    style = do
        let checkboxOrRadio = input # isOneOf ["type" @= "checkbox", "type" @= "radio"]
        checkboxOrRadio ? do
            pressable
            iconFont
            color' InputBorder
            transition "color" (ms 100) easeInOut (sec 0)
        Clay.label # has (self |> checkboxOrRadio) ? do
            pressable
            display flex
            flexDirection row
            alignItems center
            columnGap' XSmall
            fullWidth
            paddingLeft . token $ Space XSmall
        input # ("type" @= "checkbox") ? do
            before & content (iconContent MdiCheckboxBlankOutline)
            checked
                <> before
                & do
                    color' BorderFocused
                    content $ iconContent MdiCheckboxMarked

data CheckboxGroup o model action = CheckboxGroup
    { name :: MisoString
    , options :: [o]
    , label :: o -> [View model action]
    , selected :: o -> Bool
    }

instance (Eq a) => Widget (CheckboxGroup a model action) model action where
    widget' attrs CheckboxGroup{..} =
        fieldset_ [ariaRole_ "group"] $
            options <&> \o ->
                widget'
                    attrs
                    Checkbox
                        { name
                        , label = label o
                        , selected = selected o
                        }

    style = do
        sconcat ((self #) . ariaRole <$> fromList ["group", "radiogroup"]) ? do
            display flex
            flexDirection column
            rowGap' XSmall
