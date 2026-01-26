{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Plot where

import Control.Concurrent (threadDelay)
import DSL qualified
import Dashi.Components.Heading
import Dashi.Components.Plot
import Dashi.Components.Range
import Dashi.Components.Switch
import Dashi.Diagram (bottom, top)
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Colour
import Dashi.Style.Tokens
import Data.Bool (bool)
import Data.Foldable qualified as Foldable
import Data.Generics.Labels ()
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import GHC.Clock (getMonotonicTime)
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (class_)
import Miso.State qualified as State

data Model
    = Model
    { width :: Int
    , time :: Double
    , hz :: Int
    , fps :: Seq (Double, Double)
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
        , fps = mempty
        , showAxes = True
        , showGrid = True
        }

data Action
    = NoOp
    | Setup
    | Tick Double
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

tick' :: Sink Action -> IO ()
tick' sink = sink . Tick =<< getMonotonicTime

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update Setup = do
    update UpdateWidth
    withSink tick'
update (Tick time) = do
    Model{hz, time = oldTime} <- State.get
    let minTime = time - 10
        append value = Seq.dropWhileL ((minTime >) . fst) . (|> (time, value))
    State.modify $ (#time .~ time) . if minTime > oldTime then id else #fps %~ append (1 / (time - oldTime))
    withSink \sink -> do
        threadDelay $ 1_000_000 `div` hz
        tick' sink
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
        , widget @(Plot Double)
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
                , domainTransform = (top .~ 120) . (bottom .~ 0)
                , series =
                    [ Series
                        { strokeColour = Just $ ColorOKLCHA 0.7 0.16 250 0.8
                        , fillColour = Just $ ColorOKLCHA 0.7 0.16 250 0.3
                        , values = Foldable.toList fps
                        , plotType = LinePlot
                        }
                    ]
                , showX = toMisoString
                , showY = toMisoString
                }
        , widget @(Plot Double)
            Plot
                { width
                , height = Dashi.Prelude.min width 300
                , showAxes
                , showGrid
                , padding =
                    Just
                        Padding
                            { topPadding = Absolute 0
                            , rightPadding = Absolute 0
                            , bottomPadding = Absolute $ bool 0 25 showAxes
                            , leftPadding = Absolute $ bool 0 50 showAxes
                            }
                , domainTransform =
                    (#bottomRight . #y .~ 0)
                        . expand
                            Padding
                                { topPadding = Relative 0.1
                                , rightPadding = Absolute 0.5
                                , bottomPadding = Absolute 0
                                , leftPadding = Absolute 0.5
                                }
                , series =
                    [ -- Nixpkgs stable 25.11
                      Series
                        { strokeColour = Nothing
                        , fillColour = Just $ ColorOKLCHA 0.55 0.12 264 0.75
                        , values = [(0, 64487), (1, 16519), (2, 23150), (3, 5553)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    , -- AUR
                      Series
                        { strokeColour = Nothing
                        , fillColour = Just $ ColorOKLCHA 0.3211 0 0 0.75
                        , values = [(0, 24379), (1, 9736), (2, 41177), (3, 315)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    , -- Ubuntu 26.04
                      Series
                        { strokeColour = Nothing
                        , fillColour = Just $ ColorOKLCHA 0.6405 0.1941 37.76 0.75
                        , values = [(0, 19856), (1, 8782), (2, 10111), (3, 1588)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    ]
                , showX = \case
                    d | d < 1 -> "Newest"
                    d | d < 2 -> "Outdated"
                    d | d < 3 -> "Unique"
                    _ -> "Problematic"
                , showY = toMisoString
                }
        ]
