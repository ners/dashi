{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Plot where

import Control.Concurrent (threadDelay)
import Dashi.Components.Button (Button (..), ButtonSize (..))
import Dashi.Components.Heading
import Dashi.Components.Icon (Icon (..), Phosphor (Pause, Play), Weight (Fill))
import Dashi.Components.Plot
import Dashi.Components.Range
import Dashi.Components.Switch
import Dashi.Components.Util (ariaBusy_)
import Dashi.Diagram (Point (..), bottom, top)
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Dashi.Style.Uchu
import Data.Vector.Strict qualified as Vector
import Miso.Html.Element (div_, fieldset_, p_, section_)
import Miso.Html.Property (class_)
import Miso.State qualified as State
import System.IO.Unsafe (unsafePerformIO)

data Model
    = Model
    { width :: Int
    , running :: Bool
    , time :: Double
    , hz :: Int
    , fps :: Vector (Point Double)
    , showAxis :: Bool
    , showGrid :: Bool
    , busy :: Bool
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { width = 0
        , running = True
        , time = 0
        , hz = 60
        , fps = mempty
        , showAxis = True
        , showGrid = True
        , busy = False
        }

data Action
    = NoOp
    | Setup
    | Tick Double
    | UpdateWidth
    | SetWidth Int
    | SetHz Int
    | SetShowAxis Bool
    | SetShowGrid Bool
    | SetBusy Bool
    | Start
    | Stop

plot :: Component parent Model Action
plot =
    (component initialModel update view)
        { subs = [windowSub "resize" emptyDecoder \() -> UpdateWidth]
        , mount = Just Setup
        , unmount = Just Stop
        }

getPlotWidth :: IO (Maybe Int)
getPlotWidth =
    [js|
        const e = document.querySelector('section > h2');
        return e ? e.clientWidth : null
    |]

tick' :: Sink Action -> IO ()
tick' sink = sink . Tick =<< [js| return Date.now() / 1000; |]

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update Setup = do
    update UpdateWidth
    update Start
update (Tick time) = do
    Model{time = oldTime, hz, running} <- State.get
    let minTime = time - 10
    State.modify
        $ (#time .~ time)
        . ( filtered (const $ minTime <= oldTime)
                . #fps
                %~ Vector.dropWhile ((minTime >) . x)
                . flip Vector.snoc Point{x = time, y = 1 / (time - oldTime)}
          )
    when running $ withSink \sink -> do
        threadDelay $ 1_000_000 `div` hz
        tick' sink
update UpdateWidth = do
    withSink \sink ->
        getPlotWidth >>= \case
            Nothing -> do
                threadDelay 100_000
                sink UpdateWidth
            Just w -> sink (SetWidth w)
update (SetWidth w) = #width .= w
update (SetHz hz) = #hz .= hz
update (SetShowAxis b) = #showAxis .= b
update (SetShowGrid b) = #showGrid .= b
update (SetBusy b) = #busy .= b
update Start = do
    #running .= True
    withSink tick'
update Stop = #running .= False

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Plot"
        , p_
            []
            [ text
                "Plots offer a way to visualise data sets in an intuitive, easy to understand way."
            ]
        , div_
            [class_ "controls"]
            [ fieldset_
                []
                [ widget @(Button Model Action)
                    Button
                        { label = [widget . Icon Fill $ if running then Pause else Play]
                        , onClick = Just $ if running then Stop else Start
                        , size = IconButton
                        , appearance = Default
                        }
                , widget @(Range Action)
                    Range
                        { value = hz
                        , step = 5
                        , min = 10
                        , max = 120
                        , onChange = SetHz
                        }
                , text $ toMisoString hz <> "\xA0Hz"
                ]
            , fieldset_
                []
                [ widget @(Switch Model Action)
                    Switch
                        { name = "showaxes"
                        , label = [text "Show axes"]
                        , checked = showAxis
                        , onChange = SetShowAxis
                        }
                , widget @(Switch Model Action)
                    Switch
                        { name = "showgrid"
                        , label = [text "Show grid"]
                        , checked = showGrid
                        , onChange = SetShowGrid
                        }
                , widget @(Switch Model Action)
                    Switch
                        { name = "setbusy"
                        , label = [text "Busy"]
                        , checked = busy
                        , onChange = SetBusy
                        }
                ]
            ]
        , widget' @(Plot Double)
            [ariaBusy_ busy]
            Plot
                { width
                , height = Dashi.Prelude.min width 500
                , padding =
                    Just
                        Padding
                            { bottomPadding = Absolute $ bool 1 20 showAxis
                            , rightPadding = Absolute 0
                            , leftPadding = Absolute $ bool 1 25 showAxis
                            , topPadding = Absolute $ bool 1 10 showAxis
                            }
                , domainTransform = (top .~ 120) . (bottom .~ 0)
                , series =
                    [ Series
                        { strokeColour = Just . uchuAlpha $ UchuAlpha Blue 0.8
                        , fillColour = Just . uchuAlpha $ UchuAlpha Blue 0.3
                        , values = fps
                        , plotType = LinePlot
                        }
                    ]
                , xAxis =
                    Axis
                        { showAxis
                        , showGrid
                        , ticks = Time
                        , renderTick = \t -> unsafePerformIO [js| return new Date(${t} * 1000).toLocaleTimeString(); |]
                        }
                , yAxis =
                    Axis
                        { showAxis
                        , showGrid
                        , ticks = Numeric
                        , renderTick = toMisoString
                        }
                }
        , widget' @(Plot Double)
            [ariaBusy_ busy]
            Plot
                { width
                , height = Dashi.Prelude.min width 300
                , padding =
                    Just
                        Padding
                            { topPadding = Absolute 0
                            , rightPadding = Absolute 0
                            , bottomPadding = Absolute $ bool 0 25 showAxis
                            , leftPadding = Absolute $ bool 0 50 showAxis
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
                        , fillColour = Just . uchuAlpha $ UchuAlpha Blue 1
                        , values =
                            Vector.fromList
                                $ uncurry Point
                                <$> [(0, 64487), (1, 16519), (2, 23150), (3, 5553)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    , -- AUR
                      Series
                        { strokeColour = Nothing
                        , fillColour = Just . uchuAlpha $ UchuAlpha Orange 1
                        , values =
                            Vector.fromList
                                $ uncurry Point
                                <$> [(0, 24379), (1, 9736), (2, 41177), (3, 315)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    , -- Ubuntu 26.04
                      Series
                        { strokeColour = Nothing
                        , fillColour = Just . uchuAlpha $ UchuAlpha Green 1
                        , values =
                            Vector.fromList
                                $ uncurry Point
                                <$> [(0, 19856), (1, 8782), (2, 10111), (3, 1588)]
                        , plotType = BarPlot{barWidth = 0.2}
                        }
                    ]
                , xAxis =
                    Axis
                        { showAxis
                        , showGrid
                        , ticks = Time
                        , renderTick = \case
                            d | d < 1 -> "Newest"
                            d | d < 2 -> "Outdated"
                            d | d < 3 -> "Unique"
                            _ -> "Problematic"
                        }
                , yAxis =
                    Axis
                        { showAxis
                        , showGrid
                        , ticks = Numeric
                        , renderTick = toMisoString
                        }
                }
        ]
