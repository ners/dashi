{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Checkbox where

import Dashi.Components.Checkbox
import Dashi.Components.Heading
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (disabled_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

checkbox :: Component parent Model Action
checkbox = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Checkbox"
        , p_ [] [text "A checkbox is an input control that allows a user to select one or more options from a number of choices."]
        , div_
            []
            [ widget @(Checkbox Model Action)
                Checkbox
                    { name = "checkbox"
                    , label = [text "Default checkbox"]
                    , selected = False
                    , onChecked = const NoOp
                    }
            ]
        , div_
            []
            [ widget' @(Checkbox Model Action)
                [disabled_]
                Checkbox
                    { name = "checkbox"
                    , label = [text "Disabled checkbox"]
                    , selected = False
                    , onChecked = const NoOp
                    }
            ]
        ]
