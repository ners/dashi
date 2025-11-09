{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Form where

import Dashi.Components.ActionBar
import Dashi.Components.Button
import Dashi.Components.Button qualified as Button
import Dashi.Components.Checkbox
import Dashi.Components.Form
import Dashi.Components.Heading
import Dashi.Components.Radio
import Dashi.Components.TextArea
import Dashi.Components.TextField
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (a_, p_, section_)
import Miso.Html.Element qualified as Miso
import Miso.Html.Property (href_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

form :: Component parent Model Action
form = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Form"
        , p_ [] [text "A form allows users to input information."]
        , Miso.form
            []
            [ widget @(FormField _ Model Action) @Model @Action
                FormField
                    { legend = [text "Username"]
                    , required = True
                    , field =
                        TextField
                            { name = "username"
                            , type' = TextField.Text
                            , value = Nothing
                            , isValid = True
                            }
                    , messages = []
                    }
            , widget' @(FormField _ Model Action) @Model @Action
                [autocomplete_ "current-password"]
                FormField
                    { legend = [text "Password"]
                    , required = True
                    , field =
                        TextField
                            { name = "password"
                            , type' = TextField.Password
                            , value = Nothing
                            , isValid = True
                            }
                    , messages = []
                    }
            , widget @(FormField _ Model Action) @Model @Action
                FormField
                    { legend = [text "What is the airspeed velocity of an unladen swallow?"]
                    , required = True
                    , field =
                        TextArea
                            { name = "swallow"
                            , value = Nothing
                            , isValid = True
                            }
                    , messages = []
                    }
            , widget @(FormField (RadioGroup _ Model Action) Model Action) @Model @Action
                FormField
                    { legend = [text "Do you like Haskell?"]
                    , required = True
                    , field =
                        RadioGroup
                            { name = "haskell"
                            , options = [True, False]
                            , label = \case
                                True -> [text "Yeah!"]
                                False -> [text "Getting there"]
                            , selected = const False
                            }
                    , messages = []
                    }
            , widget @(FormField (Checkbox Model Action) Model Action) @Model @Action
                FormField
                    { legend = []
                    , required = True
                    , field =
                        Checkbox
                            { name = "terms"
                            , label = [text "I have read and accept the ", a_ [href_ "#"] [text "terms and conditions"]]
                            , selected = True
                            }
                    , messages = []
                    }
            , widget
                ActionBar
                    { left = []
                    , centre = []
                    , right =
                        [ widget @(Button Model Action) @Model @Action
                            Button
                                { size = Button.DefaultSize
                                , appearance = Subtle
                                , label = [text "Cancel"]
                                }
                        , widget @(Button Model Action) @Model @Action
                            Button
                                { size = Button.DefaultSize
                                , appearance = Primary
                                , label = [text "Sign up"]
                                }
                        ]
                    }
            ]
        ]
