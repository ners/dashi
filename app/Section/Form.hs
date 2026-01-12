{-# LANGUAGE ImpredicativeTypes #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Form where

import Dashi.Components.ActionBar
import Dashi.Components.Button
import Dashi.Components.Button qualified as Button
import Dashi.Components.Checkbox
import Dashi.Components.Form
import Dashi.Components.Heading
import Dashi.Components.TextField
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util
import Dashi.Prelude hiding (view)
import Dashi.Style.Tokens
import Miso hiding (update, view)
import Miso.Html.Element (form_, p_, section_)

data Model = Model
    { username :: Maybe MisoString
    , password :: Maybe MisoString
    , staySignedIn :: Bool
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { username = mempty
        , password = mempty
        , staySignedIn = False
        }

data Action
    = NoOp
    | SetUsername MisoString
    | SetPassword MisoString
    | SetStaySignedIn Bool

form :: Lens' parent Model -> Model -> Component parent Model Action
form l model =
    (component model update view)
        { bindings = [l <---> id]
        }

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update (SetUsername t) = #username ?= t
update (SetPassword t) = #password ?= t
update (SetStaySignedIn b) = #staySignedIn .= b

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Form"
        , p_ [] [text "A form allows users to input information."]
        , form_
            []
            [ widget' @(FormField _ Model Action) @Model @Action
                [autocomplete_ "username"]
                FormField
                    { legend = [text "Username"]
                    , required = True
                    , field =
                        TextField
                            { name = "username"
                            , type' = TextField.Text
                            , value = username
                            , isValid = True
                            , onChange = SetUsername
                            }
                    , messages = [(Subtle, "You can use letters, numbers, and periods")]
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
                            , value = password
                            , isValid = True
                            , onChange = SetPassword
                            }
                    , messages = []
                    }
            , widget @(FormField (Checkbox Model Action) Model Action) @Model @Action
                FormField
                    { legend = []
                    , required = False
                    , field =
                        Checkbox
                            { name = "terms"
                            , label = [text "Always sign in on this device"]
                            , selected = staySignedIn
                            , onChecked = SetStaySignedIn
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
