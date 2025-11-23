{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Main where

import Control.Applicative ((<|>))
import Control.Lens qualified as Lens
import Control.Lens.Operators
import Control.Monad (liftM2)
import Dashi.Components.Button (Button (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Heading
import Dashi.Components.Select (Select (..))
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Layout.Page (Page (..))
import Dashi.Style qualified as Style
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Colour qualified as Colour.Scheme
import Dashi.Style.Tokens
import Dashi.Util
import Data.Generics.Labels ()
import Data.List.Extra qualified as List
import Data.String (IsString (fromString))
import Data.Text qualified as Text
import GHC.Generics (Generic)
import Language
import Language.Fluent.Bundle (Bundle (..), buildBundle)
import Language.Fluent.Syntax.Resource qualified as Resource
import Language.Javascript.JSaddle qualified as JSaddle
import Miso
import Miso.Html.Element (a_, dialog_, div_, img_, li_, ul_)
import Miso.Html.Event (onChange, onClick)
import Miso.Html.Property (aria_, hidden_, id_, src_)
import Section (SectionId)
import Section qualified
import Web.Font.MDI
import Prelude hiding (init)

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = run (startApp app)

instance Eq (a -> b) where
    (==) _ _ = True

deriving stock instance Eq Bundle

instance Show Bundle where
    show Bundle{..} = "Bundle{locales=" <> show locales <> "}"

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
    , colourScheme :: Colour.Scheme
    , section :: Section.Model
    , navOpen :: Bool
    }
    deriving stock (Eq, Generic)

instance Translatable Model where
    getBundle = responseData . bundle

emptyModel :: Model
emptyModel =
    Model
        { bundle = NotRequested
        , colourScheme = Colour.Scheme.Light
        , section = Section.initialModel
        , navOpen = False
        }

data Action
    = Setup
    | SetNavOpen Bool
    | SetLanguage Language
    | SetBundle (Either String Bundle)
    | SetColourScheme Colour.Scheme
    | SetCurrentSection SectionId
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
    initComponent :: Component parent Model Action
    initComponent = component emptyModel (liftM2 (>>) traceAction appUpdate) appView

setSystemColourScheme :: JSM Action
setSystemColourScheme =
    JSaddle.jsg @String "window"
        >>= Lens.view
            ( JSaddle.js1 @String @String "matchMedia" "(prefers-color-scheme: dark)"
                . JSaddle.js @_ @String "matches"
            )
        >>= JSaddle.valToBool
        <&> SetColourScheme . \case
            True -> Colour.Scheme.Dark
            False -> Colour.Scheme.Light

appUpdate :: Action -> Effect parent Model Action
appUpdate Setup = do
    -- TODO take this from header / local storage / browser settings ...
    appUpdate $ SetLanguage Language.English
    io setSystemColourScheme
    -- io setNavOpen
    -- TODO detect if we are in ghcid
    io_ do
        let createElement = JSaddle.js1 @String @String "createElement"
            setAttribute = JSaddle.js2 @String @String @String "setAttribute"
            appendChild :: JSaddle.JSM JSaddle.JSVal -> JSaddle.JSF
            appendChild = JSaddle.js1 @String "appendChild"
        doc <- JSaddle.jsg @String "document"
        head <- doc ^. JSaddle.js @_ @String "head"
        head
            ^. JSaddle.js1 @String @String "getElementsByTagName" "title"
                . JSaddle.js1 @String @Int "item" 0
                . JSaddle.js0 @String "remove"
        head ^. appendChild do
            e <- doc ^. createElement "meta"
            e ^. setAttribute "charset" "utf-8"
            pure e
        head ^. appendChild do
            e <- doc ^. createElement "meta"
            e ^. setAttribute "name" "color-scheme"
            e ^. setAttribute "content" "dark light"
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
appUpdate (SetNavOpen navOpen) = #navOpen .= navOpen
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
appUpdate (SetColourScheme scheme) = do
    #colourScheme .= scheme
    io_ do
        doc <- JSaddle.jsg @String "document"
        html <- doc ^. JSaddle.js @_ @String "documentElement"
        Property name value <- pure $ tokenAttr scheme
        html ^. JSaddle.js2 @String "setAttribute" name value
        pure ()
appUpdate (SetCurrentSection sectionId) = #section . #current .= sectionId
appUpdate NoOp = pure ()

appView :: Model -> View Model Action
appView model =
    widget @(Page Model Action)
        Page
            { banner = Nothing
            , topBar =
                Just
                    [ widget' @(Button Model Action)
                        [id_ "nav-toggle", onClick . SetNavOpen . not $ model.navOpen]
                        Button
                            { size = Button.IconButton
                            , appearance = Subtle
                            , label = [widget $ if model.navOpen then MdiMenuClose else MdiMenuOpen]
                            }
                    , img_ [src_ "/static/icon.svg"]
                    , widget . Heading XLarge $ unsafeTranslate model "hello"
                    , widget' @(Select Language Model Action)
                        [ appearance_ Subtle
                        , onChange $ maybe NoOp SetLanguage . Language.fromCode
                        ]
                        Select
                            { name = "language"
                            , options = [minBound .. maxBound]
                            , selected =
                                let req = requestData model.bundle
                                    res = List.firstJust Language.fromLocale . (.locales) =<< responseData model.bundle
                                 in maybe (const False) (==) $ req <|> res
                            , value = Language.code
                            , label = pure . text . fromText . Text.toUpper . Language.code
                            }
                    , widget' @(Button Model Action)
                        [onClick . SetColourScheme . cycleSucc $ model.colourScheme]
                        Button
                            { size = Button.IconButton
                            , appearance = Subtle
                            , label =
                                [ widget $ case model.colourScheme of
                                    Colour.Scheme.Light -> MdiWhiteBalanceSunny
                                    Colour.Scheme.Dark -> MdiWeatherNight
                                ]
                            }
                    ]
            , sideNav =
                Just
                    [ ul_
                        [hidden_ $ not model.navOpen]
                        [ li_
                            [aria_ "current" "page" | sectionId == model.section.current]
                            [ a_
                                [onClick (SetCurrentSection sectionId)]
                                [text . capitalise . unpascal . misoShow $ sectionId]
                            ]
                        | sectionId <- [minBound .. maxBound]
                        ]
                    ]
            , main_ =
                [ div_ [key_ . misoShow $ model.section.current] +> Section.section model.section
                , dialog_ [textProp "closedby" "any"] [widget $ Heading Large "Dialog!"]
                ]
            , aside = Nothing
            }
