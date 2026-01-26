{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.DesignTokens where

import Dashi.Components.Heading
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

tokens :: Component parent Model Action
tokens = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Design tokens"
        , p_ [] [text "Design tokens are name and value pairings that represent small, repeatable design decisions. A token can be a colour, font style, unit of white space, or even a motion animation designed for a specific need."]
        ]
