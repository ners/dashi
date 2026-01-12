{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Radio where

import Clay hiding (fullWidth, label, legend, name, option, selected, span_, type_)
import Dashi.Components.Icon (iconContent)
import Dashi.Components.Util (ariaRole_)
import Dashi.Prelude hiding ((#), (&))
import Dashi.Style.Util
import Miso.Html.Element (fieldset_, input_, label_, span_)
import Miso.Html.Property (name_, selected_, type_)
import Web.Font.MDI (MDI (MdiRadioboxBlank, MdiRadioboxMarked))

data Radio model action = Radio
    { name :: MisoString
    , label :: [View model action]
    , selected :: Bool
    }

instance Widget (Radio model action) model action where
    widget' attrs Radio{..} =
        label_
            []
            [ input_ $ type_ "radio" : name_ name : selected_ selected : attrs
            , span_ [] label
            ]
    style =
        -- Shared style is applied in the Checkbox component
        input # ("type" @= "radio") ? do
            borderRadiusAll $ pct 50
            before & content (iconContent MdiRadioboxBlank)
            checked <> before & content (iconContent MdiRadioboxMarked)

data RadioGroup o model action = RadioGroup
    { name :: MisoString
    , options :: [o]
    , label :: o -> [View model action]
    , selected :: o -> Bool
    }

instance (Eq a) => Widget (RadioGroup a model action) model action where
    widget' attrs RadioGroup{..} =
        fieldset_ [ariaRole_ "radiogroup"]
            $ options
            <&> \o ->
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
