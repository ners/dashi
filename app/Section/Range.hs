{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Range where

import Dashi.Components.Heading
import Dashi.Components.Range
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (p_, section_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

range :: Component parent Model Action
range = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Range"
        , p_ [] [text "A range lets users choose an approximate value on a slider."]
        , widget Range{value = 50, step = 1, min = 1, max = 100}
        ]
