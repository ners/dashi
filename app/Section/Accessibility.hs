{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Accessibility where

import Dashi.Components.Heading
import Dashi.Prelude hiding (view)
import Dashi.Style.Tokens
import Miso hiding (update, view)
import Miso.Html.Element (p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

accessibility :: Component parent Model Action
accessibility = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Accessibility"
        , p_ [] [text "An accessible app means people of all abilities can interact with, understand, and navigate it."]
        , p_ [] [text "Dashi components ship with built-in accessibility features, such as keyboard support and sensible ARIA usage. However, you still need to review your patterns, content, and interactions so your app is accessible end-to-end."]
        ]
