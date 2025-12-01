{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-missing-poly-kind-signatures #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Select where

import Clay hiding (label, name, selected, value)
import Dashi.Components.Widget
import Dashi.Style.Util
import Miso
import Miso.Html.Element (option_, select_)
import Miso.Html.Property (name_, selected_, value_)
import Prelude

data Option model action = Option
    { value :: MisoString
    , label :: [View model action]
    , selected :: Bool
    }

data Select o model action = Select
    { name :: MisoString
    , options :: [o]
    , selected :: o -> Bool
    , value :: o -> MisoString
    , label :: o -> [View model action]
    }

instance Widget (Option model action) model action where
    widget' attrs Option{..} = option_ (value_ value : selected_ selected : attrs) label
    style = pure ()

instance (Eq o) => Widget (Select o model action) model action where
    widget' attrs Select{..} =
        select_
            (name_ name : attrs)
            [ widget
                Option
                    { value = value o
                    , label = label o
                    , selected = selected o
                    }
            | o <- options
            ]
    style =
        Clay.select ? do
            pressable
            after & do
                display block
                content $ stringContent "chevron"
