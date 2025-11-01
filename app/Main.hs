{-# LANGUAGE CPP #-}

module Main where

import Dashi.Components.ActionBar (ActionBar (..))
import Dashi.Components.Button (Button (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Chart qualified as Chart
import Dashi.Components.Checkbox (Checkbox (..))
import Dashi.Components.Form (FormField (..))
import Dashi.Components.Heading
import Dashi.Components.Message (Message (Message), MessageSize (..))
import Dashi.Components.Message qualified as Message
import Dashi.Components.Radio (RadioGroup (..))
import Dashi.Components.TextArea (TextArea (..))
import Dashi.Components.TextField (TextField (TextField))
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style qualified as Style
import Dashi.Style.Tokens
import Dashi.Util
import Miso
import Miso.Html
import Miso.Html.Property (class_, disabled_, href_, id_)
import Web.Font.MDI (MDI (MdiStar))
import Prelude

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = run (startApp app)

data Model = Model
    deriving stock (Eq)

emptyModel :: Model
emptyModel = Model

data Action = Setup

app :: App Model Action
app = do
    initComponent
        { events = defaultEvents <> keyboardEvents
        , initialAction = Just Setup
        , styles = [Style Style.styleStr, Href "style.css"]
        }
  where
    initComponent :: Component ROOT Model Action
    initComponent = component emptyModel appUpdate appView

appUpdate :: Action -> Effect ROOT Model Action
appUpdate Setup = pure ()

appView :: Model -> View Model Action
appView _model =
    main_
        []
        [ widget $ Heading XLarge "Hello from dashi 👋"
        , buttons
        , icons
        , forms
        , inlineMessages
        , sectionMessages
        , diagrams
        ]

buttons :: View model action
buttons =
    section_ [id_ "buttons"] $
        [ widget $ Heading Large "Buttons"
        , div_
            [class_ "grid"]
            [ div_
                []
                [ widget'
                    [attr]
                    Button
                        { size = Button.DefaultSize
                        , appearance
                        , label = capitalise . tokenName $ appearance
                        , leftIcon
                        , rightIcon = Nothing
                        }
                ]
            | leftIcon <- [Nothing, Just MdiStar]
            , attr <- [emptyAttr_, ariaBusy_ True, disabled_]
            , appearance <- [minBound .. maxBound]
            ]
        ]

icons :: View model action
icons =
    section_ [id_ "icons"] $
        [ widget $ Heading Large "Icons"
        , div_
            [class_ "grid"]
            [ widget @MDI mdi
            | mdi <- take 120 [minBound .. maxBound]
            ]
        ]

forms :: forall model action. View model action
forms =
    section_ [id_ "forms"] $
        [ widget $ Heading Large "Forms"
        , form
            []
            [ widget
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
            , widget
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
            , widget
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
            , widget
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
            , widget
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
                        [ widget
                            Button
                                { size = Button.DefaultSize
                                , appearance = Subtle
                                , label = "Cancel"
                                , leftIcon = Nothing
                                , rightIcon = Nothing
                                }
                        , widget
                            Button
                                { size = Button.DefaultSize
                                , appearance = Primary
                                , label = "Sign up"
                                , leftIcon = Nothing
                                , rightIcon = Nothing
                                }
                        ]
                    }
            ]
        ]

inlineMessages :: View model action
inlineMessages =
    section_ [id_ "inline-messages"] $
        [ widget $ Heading Large "Inline messages"
        , widget
            Message
                { size = InlineMessage
                , appearance = Primary
                , title = Just "Software update"
                , secondary = Just "You've been upgraded to version 5.2"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Warning
                , title = Nothing
                , secondary = Just "Your bill may increase"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Danger
                , title = Nothing
                , secondary = Just "Username taken"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Success
                , title = Nothing
                , secondary = Just "Files have been added"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Discovery
                , title = Nothing
                , secondary = Nothing
                }
        ]

sectionMessages :: View model action
sectionMessages =
    section_ [id_ "section-messages"] $
        [ widget $ Heading Large "Section messages"
        , widget
            Message
                { size = SectionMessage
                , appearance = Primary
                , title = Just "Editing is restricted"
                , secondary = Just "You're not allowed to change these restrictions. It's either due to the restrictions on the page, or permission settings for this space."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Warning
                , title = Just "Cannot connect to the database"
                , secondary = Just "We're unable to save any progress at this time. Please try again later."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Success
                , title = Nothing
                , secondary = Just "The file has been uploaded."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Danger
                , title = Just "This account has been permanently deleted"
                , secondary = Just "The user `IanAtlas` no longer has access to Atlassian services."
                }
        ]

diagrams :: View model action
diagrams =
    section_ [id_ "diagrams"] $
        [ widget $ Heading Large "Diagrams"
        , div_ [] . pure $ Chart.chart 740 300 do
            Chart.plot (Chart.line "amplitude modulation" [signal [0, (0.5) .. 400]])
            Chart.plot (Chart.points "points" (signal [0, 7 .. 400]))
        ]
  where
    signal :: [Double] -> [(Double, Double)]
    signal xs = [(x, (sin (x * pi / 45) + 1) / 2 * (sin (x * pi / 5))) | x <- xs]
