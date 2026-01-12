{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Switch where

import Dashi.Components.Heading
import Dashi.Components.Switch
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

switch :: Component parent Model Action
switch = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Switch"
        , p_ [] [text "A switch is used to view or toggle between enabled or disabled states."]
        , div_
            []
            [ widget @(Switch Model Action)
                Switch
                    { name = "radio"
                    , label = [text "Default switch"]
                    , selected = False
                    }
            ]
        , div_
            []
            [ widget' @(Switch Model Action)
                [disabled_]
                Switch
                    { name = "radio"
                    , label = [text "Disabled switch"]
                    , selected = False
                    }
            ]
        ]
