{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Plot where

import Dashi.Components.Heading
import Dashi.Components.Plot
import Dashi.Prelude hiding (view)
import Dashi.Style.Colour
import Dashi.Style.Tokens
import Data.Bifunctor (second)
import Data.Generics.Labels ()
import Miso (Component, Effect, component)
import Miso.Html.Element (p_, section_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

plot :: Component parent Model Action
plot = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Plot"
        , p_ [] [text "Plots offer a way to visualise data sets in an intuitive, easy to understand way."]
        , widget
            Plot
                { plotType = LinePlot
                , width = 800
                , height = 500
                , showAxes = True
                , showGrid = True
                , padding =
                    Just
                        Padding
                            { topPadding = Absolute 0
                            , rightPadding = Absolute 20
                            , bottomPadding = Absolute 30
                            , leftPadding = Absolute 50
                            }
                , series =
                    [ Series (chartColours !! i) $ second (+ fromIntegral (2 * i)) <$> signal [0, 0.5 .. 400]
                    | i <- [0, 1, 2]
                    ]
                }
        , widget
            Plot
                { plotType = BarPlot
                , width = 800
                , height = 300
                , showAxes = True
                , showGrid = True
                , padding =
                    Just
                        Padding
                            { topPadding = Absolute 0
                            , rightPadding = Absolute 20
                            , bottomPadding = Absolute 30
                            , leftPadding = Absolute 50
                            }
                , series =
                    [ Series (chartColours !! 2) [(0, 10), (1, 15), (2, 12), (3, 22), (4, 30)]
                    , Series (chartColours !! 3) [(0, 5), (1, 8), (2, 7), (3, 10), (4, 12)]
                    ]
                }
        ]
  where
    chartColours :: [Color (Alpha OKLCH) Double]
    chartColours = flip (ColorOKLCHA 0.7 0.16) 1 <$> [250, 320, 150, 30]

    signal :: [Double] -> [(Double, Double)]
    signal xs = [(x, (sin (x * pi / 45) + 1) / 2 * sin (x * pi / 5)) | x <- xs]
