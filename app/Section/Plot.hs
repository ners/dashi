{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Plot where

import Control.Concurrent (threadDelay)
import DSL qualified
import Dashi.Components.Heading
import Dashi.Components.Plot
import Dashi.Components.Range
import Dashi.Components.Switch
import Dashi.Prelude hiding (view)
import Dashi.Style.Colour
import Dashi.Style.Tokens
import Data.Bool (bool)
import Data.Foldable (Foldable (toList))
import Data.Generics.Labels ()
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Miso (Component (initialAction, subs), Effect, FromJSVal (fromJSValUnchecked), component, emptyDecoder, windowSub, withSink)
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (class_)
import Miso.State qualified as State

data Model
    = Model
    { width :: Int
    , time :: Double
    , hz :: Int
    , values :: Seq (Double, Double)
    , showAxes :: Bool
    , showGrid :: Bool
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { width = 0
        , time = 0
        , hz = 60
        , values = mempty
        , showAxes = True
        , showGrid = True
        }

data Action
    = NoOp
    | Setup
    | Tick
    | UpdateWidth
    | SetWidth Int
    | SetHz Int
    | SetShowAxes Bool
    | SetShowGrid Bool

plot :: Component parent Model Action
plot =
    (component initialModel update view)
        { initialAction = Just Setup
        , subs = [windowSub "resize" emptyDecoder \() -> UpdateWidth]
        }

getPlotWidth :: IO Int
getPlotWidth = fromJSValUnchecked =<< DSL.eval "const e = document.querySelector('section > h2'); e ? e.clientWidth : 0"

signal :: Double -> Double
signal x = (sin (x * pi / 45) + 1) / 2 * sin (x * pi / 5)

tick :: Model -> Model
tick Model{..} =
    Model
        { time = time + 0.1
        , values = Seq.dropWhileL ((time - 100 >) . fst) . (|> (time, signal time)) $ values
        , ..
        }

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update Setup = do
    update UpdateWidth
    State.modify $ (!! 1000) . iterate tick
    update Tick
update Tick = do
    State.modify tick
    Model{hz} <- State.get
    withSink \sink -> do
        threadDelay $ 1_000_000 `div` hz
        sink Tick
update UpdateWidth = do
    withSink \sink ->
        getPlotWidth >>= \case
            0 -> do
                threadDelay 100_000
                sink UpdateWidth
            w -> sink (SetWidth w)
update (SetWidth w) = #width .= w
update (SetHz hz) = #hz .= hz
update (SetShowAxes b) = #showAxes .= b
update (SetShowGrid b) = #showGrid .= b

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Plot"
        , p_ [] [text "Plots offer a way to visualise data sets in an intuitive, easy to understand way."]
        , div_
            [class_ "controls"]
            [ widget @(Switch Model Action)
                Switch
                    { name = "showaxes"
                    , label = [text "Show axes"]
                    , checked = showAxes
                    , onChange = SetShowAxes
                    }
            , widget @(Switch Model Action)
                Switch
                    { name = "showgrid"
                    , label = [text "Show grid"]
                    , checked = showGrid
                    , onChange = SetShowGrid
                    }
            , div_
                []
                [ widget @(Range Action) Range{value = hz, step = 5, min = 10, max = 120, onChange = SetHz}
                , text $ toMisoString hz <> "\xA0Hz"
                ]
            ]
        , widget
            Plot
                { width
                , height = Dashi.Prelude.min width 500
                , showAxes
                , showGrid
                , padding =
                    Just
                        SymmetricPadding
                            { yPadding = Absolute $ bool 1 20 showAxes
                            , xPadding = Absolute $ bool 1 25 showAxes
                            }
                , domainPadding =
                    Just
                        SymmetricPadding
                            { yPadding = Relative 0.025
                            , xPadding = Absolute 0
                            }
                , series =
                    [ Series
                        { strokeColour = Just $ ColorOKLCHA 0.7 0.16 250 1
                        , fillColour = Just $ ColorOKLCHA 0.7 0.16 250 0.3
                        , values = toList values
                        }
                    ]
                }
        ]
