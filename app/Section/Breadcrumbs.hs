{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Breadcrumbs where

import Dashi.Components.Breadcrumbs
import Dashi.Components.Heading
import Dashi.Components.Link
import Dashi.Components.Util (appearance_)
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

breadcrumbs :: Component parent Model Action
breadcrumbs = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Breadcrumbs"
        , p_
            []
            [ text
                "Breadcrumbs are a navigation system used to show a user's location in a site or app."
            ]
        , widget @(Breadcrumbs Model Action)
            $ Breadcrumbs
                [ widget' @(Link Model Action)
                    [appearance_ Subtle]
                    Link{href = "#", label = [text "One"]}
                , widget' @(Link Model Action)
                    [appearance_ Subtle]
                    Link{href = "#", label = [text "Two"]}
                , widget' @(Link Model Action)
                    [appearance_ Subtle]
                    Link{href = "#", label = [text "Three"]}
                ]
        ]
