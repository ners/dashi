{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Icon where

import Dashi.Components.Heading
import Dashi.Components.Icon (Icon)
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (class_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

icon :: Component parent Model Action
icon = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Icon"
        , p_
            []
            [ text
                "An icon is a symbol representing a command, device, directory, or common action."
            ]
        , div_
            [class_ "grid"]
            [ widget @Icon mdi
            | mdi <- take (38 * 4) [minBound .. maxBound]
            ]
        ]
