{-# LANGUAGE ImpredicativeTypes #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Form where

import Control.Concurrent (threadDelay)
import Dashi.Components.ActionBar
import Dashi.Components.Button
import Dashi.Components.Button qualified as Button
import Dashi.Components.Checkbox
import Dashi.Components.Form
import Dashi.Components.Heading
import Dashi.Components.Icon (MDI (MdiSecurity))
import Dashi.Components.Message
import Dashi.Components.TextField
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (form_, p_, section_)
import Miso.Html.Property (disabled_)
import Miso.String qualified as MisoString

data Model = Model
    { username :: Maybe MisoString
    , password :: Maybe MisoString
    , staySignedIn :: Bool
    , submitInProgress :: Bool
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { username = Nothing
        , password = Nothing
        , staySignedIn = False
        , submitInProgress = False
        }

data Action
    = NoOp
    | SetUsername MisoString
    | SetPassword MisoString
    | SetStaySignedIn Bool
    | Submit
    | Reset

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
update Submit = do
    Model{..} <- get
    unless submitInProgress do
        when (isNothing username) $ #username ?= ""
        when (isNothing password) $ #password ?= ""
        let username' = fromMaybe "" username
            password' = fromMaybe "" password
        unless (MisoString.null username' || MisoString.null password') do
            #submitInProgress .= True
            withSink \sink -> do
                threadDelay 5_000_000
                sink Reset
update Reset = do
    io_ [js| [...document.forms].forEach(e => e.reset()) |]
    put initialModel

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Form"
        , p_ [] [text "A form allows users to input information."]
        , form_
            []
            [ widget' @(FormField _ Model Action) @Model @Action
                ([autocomplete_ "username"] <> [disabled_ | submitInProgress])
                FormField
                    { legend = [text "Username"]
                    , required = True
                    , field = usernameInput
                    , messages = usernameMessages
                    }
            , widget' @(FormField _ Model Action) @Model @Action
                ([autocomplete_ "new-password"] <> [disabled_ | submitInProgress])
                FormField
                    { legend = [text "Password"]
                    , required = True
                    , field = passwordInput
                    , messages = passwordMessages
                    }
            , widget' @(FormField (Checkbox Model Action) Model Action) @Model @Action
                [disabled_ | submitInProgress]
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
                    { left =
                        [ widget
                            Message
                                { size = FormMessage
                                , appearance = Subtle
                                , icon = Just . CustomIcon $ MdiSecurity
                                , title = Nothing
                                , secondary = Just "Your inputs will not be stored"
                                }
                        ]
                    , centre = []
                    , right =
                        [ widget' @(Button Model Action) @Model @Action
                            [disabled_ | submitInProgress]
                            Button
                                { size = Button.DefaultSize
                                , appearance = Subtle
                                , label = [text "Cancel"]
                                , onClick = Just Reset
                                }
                        , widget' @(Button Model Action) @Model @Action
                            ( [disabled_ | not (usernameInput.valid && passwordInput.valid)]
                                <> [ariaBusy_ submitInProgress]
                            )
                            Button
                                { size = Button.DefaultSize
                                , appearance = Primary
                                , label = [text "Sign up"]
                                , onClick = Just Submit
                                }
                        ]
                    }
            ]
        ]
  where
    usernameMessages :: [(Appearance, MisoString)]
    usernameMessages =
        case username of
            _ | submitInProgress -> []
            Nothing -> [(Subtle, "You can use letters, numbers, and periods")]
            Just "" -> [requiredInputMessage]
            Just s | MisoString.length s < 3 -> [(Danger, "Username is too short")]
            Just "ners" -> [(Danger, "Username is not available")]
            Just _ -> [(Success, "Username is available")]
    usernameInput =
        TextField
            { name = "username"
            , type' = TextField.Text
            , value = username
            , valid = none ((Danger ==) . fst) usernameMessages
            , onChange = SetUsername
            }
    passwordMessages :: [(Appearance, MisoString)]
    passwordMessages =
        case password of
            _ | submitInProgress -> []
            Nothing -> []
            Just "" -> [requiredInputMessage]
            Just s
                | MisoString.length s < 6 -> [(Danger, "Password is too short")]
                | MisoString.length s < 12 -> [(Warning, "Password is weak")]
            Just _ -> [(Success, "Password is strong")]
    passwordInput =
        TextField
            { name = "password"
            , type' = TextField.Password
            , value = password
            , valid = none ((Danger ==) . fst) passwordMessages
            , onChange = SetPassword
            }
    requiredInputMessage :: (Appearance, MisoString)
    requiredInputMessage = (Danger, "Required input")
