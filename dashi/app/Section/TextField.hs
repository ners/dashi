{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.TextField where

import Dashi.Components.Heading
import Dashi.Components.TextField
import Dashi.Components.Util (appearance_)
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Dashi.Util
import Miso.Html.Element (form_, p_, section_)
import Miso.Html.Property (placeholder_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

textField :: Component parent Model Action
textField = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Text field"
        , p_
            []
            [text "A text field is an input that allows a user to write or edit text."]
        , form_
            []
            $ mconcat
                [ [ widget . Heading Medium . capitalise . tokenName $ type'
                  | not isSubtle
                  ]
                    <> [ widget'
                            ([appearance_ Subtle | isSubtle] <> [placeholder_ "Type something here ..."])
                            TextField
                                { name = "text"
                                , type'
                                , value = Nothing
                                , valid = True
                                , onChange = const NoOp
                                }
                       ]
                | type' <- [minBound .. maxBound]
                , isSubtle <- [False, True]
                ]
        ]
