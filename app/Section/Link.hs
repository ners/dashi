{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Link where

import Dashi.Components.Heading
import Dashi.Components.Link
import Dashi.Components.Util (appearance_)
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

link :: Component parent Model Action
link = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Link"
        , p_ [] [text "A link takes people to a new location in the app or another website."]
        , div_ [] [widget @(Link Model Action) $ Link "" [text "Default link"]]
        , div_ [] [widget' @(Link Model Action) [appearance_ Subtle] $ Link "" [text "Subtle link"]]
        ]
