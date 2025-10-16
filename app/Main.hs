{-# LANGUAGE CPP #-}

module Main where

import Clay (putCss)
import Clay qualified
import Clay.Render qualified as Clay
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Style qualified as Style
import Data.Maybe (maybeToList)
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Miso
import Miso.Html
import Miso.Html.Property (aria_, class_, disabled_)
import Web.Font.MDI ()
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
        , styles = [Style . fromString . LazyText.unpack . Clay.renderWith Clay.pretty [] $ Style.style]
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
                [ Button.button (attr : baAttrs) (maybe "DefaultButton" (fromString . show) ba)
                | ba <- Nothing : (Just <$> [minBound .. maxBound])
                , let baAttrs = Button.buttonAppearance <$> maybeToList ba
                ]
            | attr <- [class_ "", disabled_, aria_ "busy" "true"]
            ]
        , div_ [] [Icon.icon i [] | i <- take 100 [minBound .. maxBound]]
        ]
