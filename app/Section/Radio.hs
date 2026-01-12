{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Radio where

import Dashi.Components.Heading
import Dashi.Components.Radio
import Dashi.Prelude hiding (view)
import Dashi.Style.Tokens
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (disabled_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

radio :: Component parent Model Action
radio = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Radio"
        , p_ [] [text "A radio input allows users to select only one option from a number of choices. Radio is generally displayed in a radio group."]
        , div_
            []
            [ widget @(Radio Model Action)
                Radio
                    { name = "radio"
                    , label = [text "Default radio"]
                    , selected = False
                    }
            ]
        , div_
            []
            [ widget' @(Radio Model Action)
                [disabled_]
                Radio
                    { name = "radio"
                    , label = [text "Disabled radio"]
                    , selected = False
                    }
            ]
        ]
