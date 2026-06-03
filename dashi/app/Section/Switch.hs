{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Switch where

import Dashi.Components.Heading
import Dashi.Components.Switch
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (disabled_)
import Miso.Router (Router (toURI))
import SectionId (ComponentId (Checkbox), SectionId (Components), sectionLink)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action
    = NoOp
    | Navigate SectionId

switch :: Component parent props Model Action
switch = component initialModel update view

update :: Action -> Effect parent props Model Action
update NoOp = pure ()
update (Navigate s) = io_ . pushURI . toURI $ s

view :: props -> Model -> View Model Action
view _ Model =
    section_
        []
        [ widget $ Heading Large "Switch"
        , p_
            []
            [text "A switch is used to view or toggle between enabled or disabled states."]
        , p_
            []
            [ text
                "Switches should provide an immediate noticeable effect that doesn’t require the user to click a button to apply the new state. For options that require a button press to apply the state, use a "
            , sectionLink Navigate $ Components Checkbox
            , " instead."
            ]
        , div_
            []
            [ widget @(Switch Model Action)
                Switch
                    { name = "radio"
                    , label = [text "Default switch"]
                    , checked = False
                    , onChange = const NoOp
                    }
            ]
        , div_
            []
            [ widget' @(Switch Model Action)
                [disabled_]
                Switch
                    { name = "radio"
                    , label = [text "Disabled switch"]
                    , checked = False
                    , onChange = const NoOp
                    }
            ]
        ]
