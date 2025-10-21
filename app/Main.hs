{-# LANGUAGE CPP #-}

module Main where

import Clay (putCss)
import Clay qualified
import Clay.Render qualified as Clay
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Message (MessageAppearance (..), messageAppearance)
import Dashi.Components.Message qualified as Message
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Components.TextField qualified as TextField
import Dashi.Style qualified as Style
import Data.Maybe (maybeToList)
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Miso
import Miso.Html
import Miso.Html.Property (aria_, class_, disabled_, required_)
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
        , styles = [Style Style.styleStr]
        }
  where
    initComponent :: Component ROOT Model Action
    initComponent = component emptyModel appUpdate appView

appUpdate :: Action -> Effect ROOT Model Action
appUpdate Setup = pure ()

appView :: Model -> View Model Action
appView model =
    main_
        []
        [ h1_ [] [text "Hello from dashi!"]
        , div_
            []
            [ div_
                []
                [ Button.button (attr : baAttrs) (iconElems <> [label])
                | ba <- Nothing : (Just <$> [minBound .. maxBound])
                , let baAttrs = Button.buttonAppearance <$> maybeToList ba
                , let label = text $ maybe "DefaultButton" (fromString . show) ba
                ]
            | attr <- [class_ "", disabled_, aria_ "busy" "true"]
            , icon <- [Nothing, Just MdiStar]
            , let iconElems = Icon.icon [] <$> maybeToList icon
            ]
        , div_ [] $ Icon.icon [] <$> take 100 [minBound .. maxBound]
        , TextField.textField [required_ True] "Field label"
        , div_ [] . pure $ Message.message [] (Just "Software update") (Just "You've been upgraded to version 5.2")
        , div_ [] . pure $ Message.message [messageAppearance WarningMessage] Nothing (Just "Your bill may increase")
        , div_ [] . pure $ Message.message [messageAppearance ErrorMessage] Nothing (Just "Username taken")
        , div_ [] . pure $ Message.message [messageAppearance ConfirmationMessage] Nothing (Just "Files have been added")
        , div_ [] . pure $ Message.message [messageAppearance InfoMessage] Nothing Nothing
        ]
