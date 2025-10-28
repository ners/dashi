{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextArea where

import Clay hiding (name, value)
import Dashi.Components.Widget
import Data.Maybe (maybeToList)
import Miso (MisoString, text)
import Miso.Html.Element (textarea_)
import Miso.Html.Property (name_)
import Prelude

data TextArea = TextArea
    { name :: MisoString
    , value :: Maybe MisoString
    , isValid :: Bool
    }

instance Widget TextArea model action where
    widget' attrs TextArea{..} = textarea_ (name_ name : attrs) . maybeToList $ text <$> value
    style =
        textarea ? do
            "resize" -: "vertical"
