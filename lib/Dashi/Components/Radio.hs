{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Radio where

import Clay hiding (fullWidth, label, legend, name, option, selected, span_, type_)
import Dashi.Components.Icon (iconContent)
import Dashi.Components.Util (ariaRole_)
import Dashi.Components.Widget
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Data.Functor ((<&>))
import Miso (MisoString, View)
import Miso.Html.Element (fieldset_, input_, label_, span_)
import Miso.Html.Property (name_, selected_, type_)
import Web.Font.MDI (MDI (MdiRadioboxBlank, MdiRadioboxMarked))
import Prelude

data Radio = Radio
    { name :: MisoString
    , label :: forall model action. [View model action]
    , selected :: Bool
    }

instance Widget Radio model action where
    widget' attrs Radio{..} =
        label_
            []
            [ input_ $ type_ "radio" : name_ name : selected_ selected : attrs
            , span_ [] label
            ]
    style =
        -- Shared style is applied in the Checkbox component
        input # ("type" @= "radio") ? do
            before & content (iconContent MdiRadioboxBlank)
            checked <> before & do
                color' BorderFocused
                content $ iconContent MdiRadioboxMarked

data RadioGroup o = RadioGroup
    { name :: MisoString
    , options :: [o]
    , label :: forall model action. o -> [View model action]
    , selected :: o -> Bool
    }

instance (Eq a) => Widget (RadioGroup a) model action where
    widget' attrs RadioGroup{..} =
        fieldset_ [ariaRole_ "radiogroup"] $
            options <&> \o ->
                widget'
                    attrs
                    Radio
                        { name
                        , label = label o
                        , selected = selected o
                        }

    style =
        -- Shared style is applied in the CheckboxGroup component
        pure ()
