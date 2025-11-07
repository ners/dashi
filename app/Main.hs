{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Main where

import Control.Applicative ((<|>))
import Control.Lens.Operators
import Control.Monad (liftM2)
import Dashi.Components.ActionBar (ActionBar (..))
import Dashi.Components.Avatar (Avatar (..), AvatarItem (..))
import Dashi.Components.Avatar qualified as Avatar
import Dashi.Components.Button (Button (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Chart qualified as Chart
import Dashi.Components.Checkbox (Checkbox (..))
import Dashi.Components.Form (FormField (..))
import Dashi.Components.Heading
import Dashi.Components.Message (Message (Message), MessageSize (..))
import Dashi.Components.Message qualified as Message
import Dashi.Components.Radio (RadioGroup (..))
import Dashi.Components.Select (Select (..))
import Dashi.Components.TextArea (TextArea (..))
import Dashi.Components.TextField (TextField (TextField))
import Dashi.Components.TextField qualified as TextField
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style qualified as Style
import Dashi.Style.Tokens
import Dashi.Util
import Data.Generics.Labels ()
import Data.List.Extra qualified as List
import Data.Maybe (isJust)
import Data.String (IsString (fromString))
import Data.Text qualified as Text
import GHC.Generics (Generic)
import Language
import Language.Fluent.Bundle (Bundle (..), buildBundle)
import Language.Fluent.Syntax.Resource qualified as Resource
import Language.Javascript.JSaddle qualified as JSaddle
import Miso
import Miso.Html
import Miso.Html.Property (class_, disabled_, href_, id_)
import Web.Font.MDI
import Prelude

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = run (startApp app)

instance Eq (a -> b) where
    (==) _ _ = True

instance Show (a -> b) where
    show _ = "<function>"

deriving stock instance Eq Bundle

deriving stock instance Show Bundle

data RequestStatus req res
    = NotRequested
    | RequestInProgress req
    | ResponseReceived (Either String res)
    deriving stock (Eq, Show, Generic)

requestData :: RequestStatus req res -> Maybe req
requestData (RequestInProgress req) = Just req
requestData _ = Nothing

responseData :: RequestStatus req res -> Maybe res
responseData (ResponseReceived (Right res)) = Just res
responseData _ = Nothing

data Model = Model
    { bundle :: RequestStatus Language Bundle
    }
    deriving stock (Eq, Generic)

instance Translatable Model where
    getBundle = responseData . bundle

emptyModel :: Model
emptyModel =
    Model
        { bundle = NotRequested
        }

data Action
    = Setup
    | SetLanguage Language
    | SetBundle (Either String Bundle)
    | NoOp
    deriving stock (Show)

traceAction :: Action -> Effect parent model action
traceAction = io_ . consoleLog . fromString . ("action: " <>) . show

app :: App Model Action
app = do
    initComponent
        { events = defaultEvents <> keyboardEvents
        , initialAction = Just Setup
        , styles = [Style Style.styleStr, Href "/static/style.css"]
        }
  where
    initComponent :: Component ROOT Model Action
    initComponent = component emptyModel (liftM2 (>>) traceAction appUpdate) appView

appUpdate :: Action -> Effect ROOT Model Action
appUpdate Setup = do
    -- TODO take this from header / local storage / browser settings ...
    appUpdate $ SetLanguage Language.English
    io_ do
        let createElement = JSaddle.js1 @String @String "createElement"
            setAttribute = JSaddle.js2 @String @String @String "setAttribute"
            appendChild :: JSaddle.JSM JSaddle.JSVal -> JSaddle.JSF
            appendChild = JSaddle.js1 @String "appendChild"
        doc <- JSaddle.jsg @String "document"
        head <- doc ^. JSaddle.js @_ @String "head"
        head
            ^. JSaddle.js1 @String @String "getElementsByTagName" "title"
            ^. JSaddle.js1 @String @Int "item" 0
            ^. JSaddle.js0 @String "remove"
        head ^. appendChild do
            e <- doc ^. createElement "meta"
            e ^. setAttribute "charset" "utf-8"
            pure e
        head ^. appendChild do
            e <- doc ^. createElement "meta"
            e ^. setAttribute "name" "viewport"
            e ^. setAttribute "content" "width=device-width, initial-scale=1, shrink-to-fit=no"
            pure e
        head ^. appendChild do
            e <- doc ^. createElement "title"
            e ^. JSaddle.jss @String @String "innerHTML" "Dashi"
            pure e
        head ^. appendChild do
            e <- doc ^. createElement "link"
            e ^. setAttribute "rel" "icon"
            e ^. setAttribute "href" "/favicon.ico"
            pure e
        head ^. appendChild do
            e <- doc ^. createElement "link"
            e ^. setAttribute "rel" "icon"
            e ^. setAttribute "href" "/static/icon.svg"
            e ^. setAttribute "type" "image/svg+xml"
            pure e
        pure ()
appUpdate (SetLanguage lang) = do
    #bundle .= RequestInProgress lang
    getText
        ("/static/" <> Language.code lang <> ".ftl")
        []
        setBundle
        (SetBundle . Left . (.body))
    io_ do
        doc <- JSaddle.jsg @String "document"
        html <- doc ^. JSaddle.js @_ @String "documentElement"
        html ^. JSaddle.js2 @String @String @String "setAttribute" "lang" (Language.code lang)
        pure ()
  where
    setBundle :: Response MisoString -> Action
    setBundle Response{body} = SetBundle . fmap (buildBundle [Language.code lang] . pure) . Resource.parse . fromMisoString $ body
appUpdate (SetBundle b) = #bundle .= ResponseReceived b
appUpdate NoOp = pure ()

appView :: Model -> View Model Action
appView model =
    main_
        []
        [ header_
            []
            [ widget . Heading XLarge $ unsafeTranslate model "hello"
            , widget' @(Select Language Model Action)
                [ appearance_ Subtle
                , onChange $ maybe NoOp SetLanguage . Language.fromCode
                ]
                Select
                    { name = "language"
                    , options = [minBound .. maxBound]
                    , selectedOption =
                        let req = requestData model.bundle
                            res = List.firstJust Language.fromLocale . (.locales) =<< responseData model.bundle
                         in req <|> res
                    , value = Language.code
                    , label = pure . text . fromText . Text.toUpper . Language.code
                    }
            , widget' @(Button Model Action)
                []
                Button
                    { size = Button.IconButton
                    , appearance = Subtle
                    , label = [widget MdiWhiteBalanceSunny]
                    }
            ]
        , avatars
        , buttons
        , icons
        , forms
        , inlineMessages
        , sectionMessages
        , diagrams
        ]

avatars :: View model action
avatars =
    section_ [id_ "avatars"] $
        [ widget $ Heading Large "Avatars"
        , div_
            [class_ "grid"]
            [ widget AvatarItem{avatar = Avatar{size = Medium, ..}, ..}
            | (username, name, initials) <-
                [ ("ueli", "Ueli Wyss", "UW")
                , ("heidi", "Heidi Müller", "HM")
                ]
            , content <- [Avatar.Identicon username, Avatar.Initials initials]
            , primaryText <- [Just name]
            , secondaryText <- [Nothing, Just username]
            , shape <- allTokens
            , isJust primaryText || isJust secondaryText
            ]
        ]

buttons :: forall model action. View model action
buttons =
    section_ [id_ "buttons"] $
        [ widget $ Heading Large "Buttons"
        , div_
            [class_ "grid"]
            [ div_
                []
                [ widget' @(Button model action)
                    [attr]
                    Button
                        { size = Button.DefaultSize
                        , appearance
                        , label = [widget (iconFor appearance) | hasIcon] <> [text . capitalise . tokenName $ appearance]
                        }
                ]
            | hasIcon <- [False, True]
            , attr <- [emptyAttr_, ariaBusy_ True, disabled_]
            , appearance <- [minBound .. maxBound]
            , let iconFor Default = MdiStar
                  iconFor Primary = MdiSendVariant
                  iconFor Subtle = MdiArrowLeft
                  iconFor Success = MdiCheck
                  iconFor Warning = MdiSecurity
                  iconFor Danger = MdiTrashCan
                  iconFor Discovery = MdiCreation
            ]
        ]

icons :: View model action
icons =
    section_ [id_ "icons"] $
        [ widget $ Heading Large "Icons"
        , div_
            [class_ "grid"]
            [ widget @MDI mdi
            | mdi <- take (28 * 4) [minBound .. maxBound]
            ]
        ]

forms :: forall model action. View model action
forms =
    section_ [id_ "forms"] $
        [ widget $ Heading Large "Forms"
        , form
            []
            [ widget @(FormField _ model action) @model @action
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
            , widget' @(FormField _ model action) @model @action
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
            , widget @(FormField _ model action) @model @action
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
            , widget @(FormField (RadioGroup _ model action) model action) @model @action
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
            , widget @(FormField (Checkbox model action) model action) @model @action
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
                        [ widget @(Button model action) @model @action
                            Button
                                { size = Button.DefaultSize
                                , appearance = Subtle
                                , label = [text "Cancel"]
                                }
                        , widget @(Button model action) @model @action
                            Button
                                { size = Button.DefaultSize
                                , appearance = Primary
                                , label = [text "Sign up"]
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
