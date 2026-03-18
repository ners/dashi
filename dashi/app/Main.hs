{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Main where

import Control.Monad.Extra (unlessM)
import Dashi.Components.Button (Button (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Heading
import Dashi.Components.Icon (MDI (..))
import Dashi.Components.Select (Select (..))
import Dashi.Components.Util
import Dashi.Layout.Page (Page (..))
import Dashi.Prelude hiding (init, (#))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Colour qualified as Colour.Scheme
import Dashi.Style.Tokens hiding (Token)
import Dashi.Util
import Data.Bifunctor (Bifunctor (second))
import Data.Either.Extra (eitherToMaybe)
import Data.List.Extra qualified as List
import Language
import Language.Fluent.Bundle (Bundle (..), buildBundle)
import Language.Fluent.Syntax.Resource qualified as Resource
import Miso.Html.Element (dialog_, div_, img_, li_, ul_)
import Miso.Html.Event (onChange)
import Miso.Html.Property (aria_, hidden_, id_, src_)
import Miso.Router (Router (route, toURI))
import Miso.String qualified as MisoString
import Section qualified
import SectionId (SectionId, sectionLink)
import UserPrefs (UserPrefs (..))
import UserPrefs qualified

#if defined(WASM) && !defined(INTERACTIVE)
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = do
    uri <- getURI
    let updateModel :: Action -> Effect parent Model Action
        updateModel = liftM2 (>>) traceAction appUpdate
        model = emptyModel & either (const id) (#section . #current .~) (route uri)
        events = defaultEvents <> keyboardEvents
    startApp events $
        (component model updateModel appView)
            { subs = [routerSub $ either (const NoOp) SetCurrentSection]
            , mount = Just Setup
#ifdef INTERACTIVE
            , styles = [Href "/static/style.css" False, Href "/static/dashi.css" False]
#endif
            }

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
    { userPrefs :: UserPrefs
    , bundle :: RequestStatus Language Bundle
    , section :: Section.Model
    , navOpen :: Bool
    }
    deriving stock (Eq, Generic)

instance Translatable Model where
    getBundle = responseData . bundle

emptyModel :: Model
emptyModel =
    Model
        { userPrefs = UserPrefs.dummy
        , bundle = NotRequested
        , section = Section.initialModel
        , navOpen = False
        }

data Action
    = NoOp
    | Setup
    | SetNavOpen Bool
    | SetLanguage Language
    | SetBundle (Either String Bundle)
    | SetColourScheme Colour.Scheme
    | SetCurrentSection SectionId
    deriving stock (Show)

traceAction :: Action -> Effect parent model action
traceAction = io_ . consoleLog . ("traceAction: " <>) . ishow

getCurrentSection :: IO (Maybe SectionId)
getCurrentSection = eitherToMaybe . route <$> getURI

appUpdate :: Action -> Effect parent Model Action
appUpdate NoOp = pure ()
appUpdate Setup =
    withSink \sink ->
        UserPrefs.get >>= \UserPrefs{..} -> do
            sink $ SetLanguage language
            sink $ SetColourScheme colourScheme
-- io setNavOpen
appUpdate (SetNavOpen navOpen) = #navOpen .= navOpen
appUpdate (SetLanguage lang) = do
    #userPrefs . #language .= lang
    io_ . UserPrefs.modify $ #language .~ lang
    #bundle .= RequestInProgress lang
    getText
        ("/static/" <> Language.code lang <> ".ftl")
        []
        setBundle
        (SetBundle . Left . (.body))
    io_ [js| document.documentElement.setAttribute('lang', ${lang}) |]
  where
    setBundle :: Response MisoString -> Action
    setBundle Response{body} =
        SetBundle
            . fmap (buildBundle [Language.locale lang] . pure)
            . Resource.parse
            . fromMisoString
            $ body
appUpdate (SetBundle b) = #bundle .= ResponseReceived b
appUpdate (SetColourScheme scheme) = do
    #userPrefs . #colourScheme .= scheme
    io_ do
        UserPrefs.modify $ #colourScheme .~ scheme
        Property name value <- pure $ tokenAttr scheme
        [js| document.documentElement.setAttribute(${name}, ${value}) |]
appUpdate (SetCurrentSection sectionId) = do
    io_
        . unlessM ((Just sectionId ==) <$> getCurrentSection)
        . pushURI
        . toURI
        $ sectionId
    #section . #current .= sectionId

appView :: Model -> View Model Action
appView model =
    widget @(Page Model Action)
        Page
            { banner = Nothing
            , topBar =
                Just
                    [ widget' @(Button Model Action)
                        [id_ "nav-toggle"]
                        Button
                            { size = Button.IconButton
                            , appearance = Subtle
                            , label = [widget $ if model.navOpen then MdiMenuClose else MdiMenuOpen]
                            , onClick = Just . SetNavOpen . not $ model.navOpen
                            }
                    , img_ [src_ "/static/icon.svg"]
                    , widget . Heading XLarge $ unsafeTranslate model "hello"
                    , widget' @(Select Language Model Action)
                        [ appearance_ Subtle
                        , onChange $ either (const NoOp) SetLanguage . fromMisoStringEither
                        ]
                        Select
                            { name = "language"
                            , options = [minBound .. maxBound]
                            , selected =
                                let req = requestData model.bundle
                                    res = List.firstJust Language.fromLocale . (.locales) =<< responseData model.bundle
                                 in maybe (const False) (==) $ req <|> res
                            , value = Language.code
                            , label = pure . text . MisoString.toUpper . Language.code
                            }
                    , widget @(Button Model Action)
                        Button
                            { size = Button.IconButton
                            , appearance = Subtle
                            , label =
                                [ widget $ case model.userPrefs.colourScheme of
                                    Colour.Scheme.Light -> MdiWhiteBalanceSunny
                                    Colour.Scheme.Dark -> MdiWeatherNight
                                ]
                            , onClick = Just . SetColourScheme . cycleSucc $ model.userPrefs.colourScheme
                            }
                    ]
            , sideNav =
                Just
                    [ div_ [hidden_ $ not model.navOpen]
                        . pure
                        $ routesToUl
                            model.section.current
                            [ (s, MisoString.words . ishow $ s)
                            | s <- [minBound .. maxBound]
                            ]
                    ]
            , main_ =
                [ mount_ $ Section.section #section model.section
                , dialog_ [textProp "closedby" "any"] [widget $ Heading Large "Dialog!"]
                ]
            , aside = Nothing
            }

routesToUl :: SectionId -> [(SectionId, [MisoString])] -> View Model Action
routesToUl current routes = ul_ [] $ groupToLi <$> groups
  where
    groups =
        second (fmap . second $ drop 1) <$> List.groupOnKey (listToMaybe . snd) routes
    textLabel :: MisoString -> View Model Action
    textLabel = text . capitalise . unpascal
    groupToLi
        :: (Maybe MisoString, [(SectionId, [MisoString])]) -> View Model Action
    groupToLi (Just _, [(r, [])]) =
        li_
            [aria_ "current" "page" | r == current]
            [ sectionLink SetCurrentSection r
            ]
    groupToLi (groupLabel, group) =
        li_ []
            . mconcat
            $ [ div_ [] . pure . textLabel <$> maybeToList groupLabel
              , pure $ routesToUl current group
              ]
