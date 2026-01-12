{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Avatar where

import Dashi.Components.Avatar
import Dashi.Components.Avatar qualified as Avatar
import Dashi.Components.Heading
import Dashi.Components.Widget
import Dashi.Style.Tokens
import Data.Maybe (isJust)
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (class_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

avatar :: Component parent Model Action
avatar = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Avatar"
        , p_ [] [text "An avatar is a visual representation of a user or entity."]
        , div_
            [class_ "grid"]
            [ widget AvatarItem{avatar = Avatar{size = Medium, ..}, ..}
            | (username, name, initials) <-
                [ ("ueli", "Ueli Wyss", "UW")
                , ("heidi", "Heidi Müller", "HM")
                ]
            , content <- [Avatar.Initials initials]
            , primaryText <- [Just name]
            , secondaryText <- [Nothing, Just username]
            , isJust primaryText || isJust secondaryText
            , shape <- allTokens
            ]
        ]
