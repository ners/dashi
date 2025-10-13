{-# LANGUAGE CPP #-}

module Main where

import Miso
import Miso.Html
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
        , styles = [Href "style.css"]
        }
  where
    initComponent :: Component ROOT Model Action
    initComponent = component emptyModel appUpdate appView

appUpdate :: Action -> Effect ROOT Model Action
appUpdate Setup = pure ()

appView :: Model -> View Model Action
appView model = main_ [] [ h1_ [] [ text "Hello from dashi!" ] ]
