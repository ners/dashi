{-# LANGUAGE CPP #-}

module Main where

import Clay (putCss)
import Dashi.Components.Button (Button (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Message (Message (Message), MessageSize (..))
import Dashi.Components.Message qualified as Message
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util (ariaBusy_)
import Dashi.Style qualified as Style
import Dashi.Style.Tokens
import Dashi.Util (capitalise, emptyAttr_)
import Miso
import Miso.Html
import Miso.Html.Property (class_, disabled_, id_, required_)
import Web.Font.MDI (MDI (MdiStar))
import Prelude

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = do
    putCss Style.style
    run (startApp app)

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

buttons :: View model action
buttons =
    section_ [id_ "buttons"] $
        [ h2_ [] [text "Buttons"]
        , div_
            [class_ "grid"]
            [ div_
                []
                [ Button.view
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
            , attr <- [emptyAttr_, ariaBusy_, disabled_]
            , appearance <- [minBound .. maxBound]
            ]
        ]

icons :: View model action
icons =
    section_ [id_ "icons"] $
        [ h2_ [] [text "Icons"]
        , div_
            [class_ "grid"]
            [ Icon.view [] mdi
            | mdi <- take 124 [minBound .. maxBound]
            ]
        ]

forms :: View model action
forms =
    section_ [id_ "forms"] $
        [ h2_ [] [text "Forms"]
        , TextField.view [required_ True] "Field label"
        , Message.view
            []
            Message
                { size = FormMessage
                , appearance = Danger
                , title = Nothing
                , secondary = Just "You can use letters, numbers, and periods"
                }
        ]

appView :: Model -> View Model Action
appView _model =
    main_
        []
        [ h1_ [] [text "Hello from dashi!"]
        , buttons
        , icons
        , forms
        , div_ [] . pure $
            Message.view
                []
                Message
                    { size = InlineMessage
                    , appearance = Primary
                    , title = Just "Software update"
                    , secondary = Just "You've been upgraded to version 5.2"
                    }
        , div_ [] . pure $
            Message.view
                []
                Message
                    { size = InlineMessage
                    , appearance = Warning
                    , title = Nothing
                    , secondary = Just "Your bill may increase"
                    }
        , div_ [] . pure $
            Message.view
                []
                Message
                    { size = InlineMessage
                    , appearance = Danger
                    , title = Nothing
                    , secondary = Just "Username taken"
                    }
        , div_ [] . pure $
            Message.view
                []
                Message
                    { size = InlineMessage
                    , appearance = Success
                    , title = Nothing
                    , secondary = Just "Files have been added"
                    }
        , div_ [] . pure $
            Message.view
                []
                Message
                    { size = InlineMessage
                    , appearance = Discovery
                    , title = Nothing
                    , secondary = Nothing
                    }
        , Message.view
            []
            Message
                { size = SectionMessage
                , appearance = Primary
                , title = Just "Editing is restricted"
                , secondary = Just "You're not allowed to change these restrictions. It's either due to the restrictions on the page, or permission settings for this space."
                }
        , Message.view
            []
            Message
                { size = SectionMessage
                , appearance = Warning
                , title = Just "Cannot connect to the database"
                , secondary = Just "We're unable to save any progress at this time. Please try again later."
                }
        , Message.view
            []
            Message
                { size = SectionMessage
                , appearance = Success
                , title = Nothing
                , secondary = Just "The file has been uploaded."
                }
        , Message.view
            []
            Message
                { size = SectionMessage
                , appearance = Danger
                , title = Just "This account has been permanently deleted"
                , secondary = Just "The user `IanAtlas` no longer has access to Atlassian services."
                }
        ]
