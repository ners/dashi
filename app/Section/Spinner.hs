{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Spinner where

import Dashi.Components.Heading
import Dashi.Components.Spinner
import Dashi.Prelude hiding (view)
import Dashi.Style.Tokens
import Miso hiding (update, view)
import Miso.Html.Element (p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

spinner :: Component parent Model Action
spinner = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Spinner"
        , p_ [] [text "A spinner is an animated spinning icon that lets users know content is being loaded."]
        , widget Spinner
        ]
