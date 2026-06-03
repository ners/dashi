{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Heading where

import Dashi.Components.Heading
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (div_, p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

heading :: Component parent props Model Action
heading = component initialModel update view

update :: Action -> Effect parent props Model Action
update NoOp = pure ()

view :: props -> Model -> View Model Action
view _ Model =
    section_
        []
        [ widget $ Heading Large "Heading"
        , p_
            []
            [ text
                "A heading is a typography component used to display text in different sizes and formats."
            ]
        , p_
            []
            [ text
                "Use a Heading component for all page titles and subheadings to introduce content. Headings are sized to contrast with content, increase visual hierarchy, and help readers easily understand the structure of content."
            ]
        , div_
            []
            [ widget . Heading size . ("Heading " <>) . toMisoString $ show size
            | size <- [maxBound, pred maxBound .. minBound]
            ]
        ]
