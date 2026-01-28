{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Plot where

import Clay ((-:), (?))
import Clay qualified
import Dashi.Diagram
import Dashi.Prelude hiding (none, transform, (&))
import Dashi.Style.Colour (Alpha)
import Data.Function ((&))
import Data.List qualified as List
import Data.List.Extra qualified as List
import Data.Vector.Strict qualified as Vector
import Graphics.Color.Space.OKLAB.LCH
import Miso.Html.Property qualified as Svg
import Miso.String qualified as MisoString
import Miso.Svg qualified as Svg
import Miso.Svg.Property qualified as Svg

data PlotType num = LinePlot | BarPlot {barWidth :: num}
    deriving stock (Eq, Show)

data Series num = Series
    { strokeColour :: Maybe (Color (Alpha OKLCH) Double)
    , fillColour :: Maybe (Color (Alpha OKLCH) Double)
    , values :: Vector (Point num)
    , plotType :: PlotType num
    }

data PaddingAmount num
    = Relative num
    | Absolute num

absolutePadding :: (Num num) => num -> PaddingAmount num -> num
absolutePadding total (Relative r) = total * r
absolutePadding _ (Absolute a) = a

data Padding num
    = SymmetricPadding
        { yPadding :: PaddingAmount num
        , xPadding :: PaddingAmount num
        }
    | Padding
        { topPadding :: PaddingAmount num
        , rightPadding :: PaddingAmount num
        , bottomPadding :: PaddingAmount num
        , leftPadding :: PaddingAmount num
        }

expand :: (Num num) => Padding num -> Rect num -> Rect num
expand SymmetricPadding{..} r =
    expand
        Padding
            { topPadding = yPadding
            , rightPadding = xPadding
            , bottomPadding = yPadding
            , leftPadding = xPadding
            }
        r
expand Padding{..} r =
    r
        & #topLeft %~ offsetPoint (subtract $ padX leftPadding) (subtract $ padY topPadding)
        & #bottomRight %~ offsetPoint (+ padX rightPadding) (+ padY bottomPadding)
  where
    (absolutePadding -> padX, absolutePadding -> padY) = rectSize r

contract :: (Num num) => Padding num -> Rect num -> Rect num
contract SymmetricPadding{..} r =
    contract
        Padding
            { topPadding = yPadding
            , rightPadding = xPadding
            , bottomPadding = yPadding
            , leftPadding = xPadding
            }
        r
contract Padding{..} r =
    r
        & #topLeft %~ offsetPoint (+ padX leftPadding) (+ padY topPadding)
        & #bottomRight %~ offsetPoint (subtract $ padX rightPadding) (subtract $ padY bottomPadding)
  where
    (absolutePadding -> padX, absolutePadding -> padY) = rectSize r

data Plot num = Plot
    { width :: Int
    -- ^ The overall width of the canvas, including padding and plot area
    , height :: Int
    -- ^ The overall height of the canvas, including padding and plot area
    , padding :: Maybe (Padding num)
    -- ^ The space from the edge of the canvas to the plot area
    , domainTransform :: Rect num -> Rect num
    -- ^ The transformation of the domain, e.g. padding or forcing a 0 baseline.
    , showAxes :: Bool
    {- ^ Whether to render plot axes
    TODO: separate X and Y
    -}
    , showGrid :: Bool
    {- ^ Whether to render plot grid
    TODO: separate X and Y
    -}
    , series :: [Series num]
    -- ^ The series to plot
    , showX :: num -> MisoString
    -- ^ The function to render ticks on the X axis
    , showY :: num -> MisoString
    -- ^ The function to render ticks on the Y axis
    }

instance (RealFrac num, ToMisoString num) => Widget (Plot num) model action where
    widget' attrs Plot{..} =
        Svg.svg_
            ( Svg.width_ (toMisoString width)
                : Svg.height_ (toMisoString height)
                : Svg.viewBox_ (MisoString.unwords [toMisoString viewBox.topLeft.x, toMisoString viewBox.topLeft.y, toMisoString width, toMisoString height])
                : Svg.className "plot"
                : attrs
            )
            . mconcat
            $ [ if showGrid then gridElements else []
              , if showAxes then axisElements else []
              , plotElements
              ]
      where
        width', height' :: num
        width' = fromIntegral width
        height' = fromIntegral height

        viewBox :: Rect num
        viewBox =
            Rect
                { topLeft = Point{x = 0, y = 0}
                , bottomRight = Point{x = width', y = height'}
                }

        swap :: Lens' s a -> Lens' s a -> s -> s
        swap a b x = x & a .~ (x ^. b) & b .~ (x ^. a)

        (<~>) :: Lens' s a -> Lens' s a -> s -> s
        (<~>) = swap

        swapY :: Rect num -> Rect num
        swapY = (#topLeft . #y) <~> (#bottomRight . #y)

        paddedViewBox = viewBox & maybe id contract padding & swapY

        gridElements :: [View model action]
        gridElements =
            toSVG [Svg.stroke_ (axisColour 0.5), Svg.strokeWidth_ "1"]
                . translateDomain paddedViewBox domain
                $ [Shape $ Line Point{x, y = t} Point{x, y = b} | hasNonBarPlots, x <- ticksX]
                <> [Shape $ Line Point{x = l, y} Point{x = r, y} | y <- ticksY]
          where
            Rect{topLeft = Point{x = l, y = t}, bottomRight = Point{x = r, y = b}} = domain

        axisElements :: [View model action]
        axisElements =
            mconcat
                . mconcat
                $ [ mkAxis <$> inViewBox [yAxis, xAxis]
                  , concatMap mkTickX ticksX
                  , concatMap mkTickY ticksY
                  ]
          where
            Rect{..} = domain
            topRight' = Point{x = bottomRight.x, y = topLeft.y}
            bottomLeft' = Point{x = topLeft.x, y = bottomRight.y}
            mkAxis :: (ToSVG s num) => s -> [View model action]
            mkAxis = toSVG [Svg.stroke_ (axisColour 1), Svg.strokeWidth_ "1"]
            xAxis, yAxis :: Line num
            xAxis = Line topLeft topRight'
            yAxis = Line topLeft bottomLeft'
            inViewBox :: (Shape s num) => s -> s
            inViewBox = translateDomain paddedViewBox domain

            mkTickX, mkTickY :: num -> [[View model action]]
            mkTickX x =
                [ mkAxis $ Line p (offsetPoint id (+ 5) p)
                , toSVG
                    [Svg.dominantBaseline_ "hanging"]
                    Text
                        { position = offsetPoint id (+ 8) p
                        , anchor = Middle
                        , content = showX x
                        }
                ]
              where
                p = inViewBox Point{x, y = topLeft.y}

            mkTickY y =
                [ mkAxis $ Line (offsetPoint (subtract 5) id p) p
                , toSVG
                    [Svg.dominantBaseline_ "middle"]
                    Text
                        { position = offsetPoint (subtract 8) id p
                        , anchor = End
                        , content = showY y
                        }
                ]
              where
                p = inViewBox Point{x = topLeft.x, y}

        isBarPlot :: PlotType num -> Bool
        isBarPlot BarPlot{} = True
        isBarPlot _ = False

        barPlotSeries :: [Series num]
        barPlotSeries = filter (isBarPlot . plotType) series

        barPlotWidth :: PlotType num -> num
        barPlotWidth BarPlot{barWidth} = barWidth
        barPlotWidth _ = 0

        totalBarPlotWidth :: num
        totalBarPlotWidth = sum $ barPlotWidth . plotType <$> barPlotSeries

        plotElements :: [View model action]
        plotElements =
            mconcat
                [ concatMap (uncurry renderLinePlot) . filter (not . isBarPlot . plotType . fst) $ zip series seriesBoundingBoxes
                , let widths = List.scanl' (+) 0 $ barPlotWidth . plotType <$> barPlotSeries
                   in concatMap (uncurry renderBarPlot) $ zip widths barPlotSeries
                ]

        renderLinePlot :: Series num -> Rect num -> [View model action]
        renderLinePlot Series{..} Rect{..} =
            mconcat
                . catMaybes
                $ [ line <$> strokeColour
                  , area <$> fillColour
                  ]
          where
            bottomRight' = bottomRight{y = domain.topLeft.y}
            bottomLeft' = bottomRight'{x = topLeft.x}
            line colour =
                toSVG
                    [ Svg.fill_ "none"
                    , Svg.stroke_ $ toMisoString colour
                    , Svg.strokeLinecap_ "round"
                    , Svg.strokeWidth_ "2"
                    ]
                    . translateDomain paddedViewBox domain
                    $ Polyline{points = Vector.toList values}
            area colour =
                toSVG
                    [ Svg.fill_ $ toMisoString colour
                    , Svg.stroke_ "none"
                    ]
                    . translateDomain paddedViewBox domain
                    $ Polygon{points = bottomRight' : bottomLeft' : Vector.toList values}

        renderBarPlot :: num -> Series num -> [View model action]
        renderBarPlot leftOffset Series{..} =
            flip concatMap values \Point{..} ->
                let
                    l = x + leftOffset - totalBarPlotWidth / 2
                    r = l + barPlotWidth plotType
                 in
                    toSVG
                        [ Svg.fill_ $ maybe "none" toMisoString fillColour
                        , Svg.stroke_ $ maybe "none" toMisoString strokeColour
                        ]
                        . translateDomain paddedViewBox domain
                        $ boundingBoxOfPoints1
                            [ Point{x = l, y}
                            , Point{x = r, y = 0}
                            ]

        seriesBoundingBoxes :: [Rect num]
        seriesBoundingBoxes = boundingBox . values <$> series

        domain :: Rect num
        domain = swapY . domainTransform . swapY $ boundingBox seriesBoundingBoxes

        axisColour :: Double -> MisoString
        axisColour = toMisoString . ColorOKLCHA 0.7 0 0

        hasNonBarPlots = not $ all (isBarPlot . plotType) series

        ticksX, ticksY :: [num]
        ticksX =
            if hasNonBarPlots
                then calculateTicks x $ width `div` 100
                else List.sort . List.nubOrd $ concatMap (fmap x . Vector.toList . values) series
        ticksY = calculateTicks y $ height `div` 80

        -- "Nice Numbers" algorithm to find human-readable tick values
        calculateTicks :: (Point num -> num) -> Int -> [num]
        calculateTicks dim targetCount
            | dMin >= dMax = [dMin]
            | otherwise = (niceStep *) . fromIntegral <$> [startIdx .. endIdx]
          where
            (dMin, dMax) = minMax dim domain
            range = dMax - dMin
            roughStep = range / fromIntegral (max 1 targetCount)

            -- Calculate magnitude of the step (power of 10)
            e = floor @Double @Int (logBase 10 $ realToFrac roughStep)
            e10 = max 1 $ 10 ^^ e
            fraction = roughStep / e10

            -- Round to nearest nice step (1, 2, 5, 10)
            niceFraction
                | fraction < 1.5 = 1
                | fraction < 3.5 = 2
                | fraction < 7.5 = 5
                | otherwise = 10

            niceStep = niceFraction * e10

            -- Calculate start and end indices
            startIdx, endIdx :: Int
            startIdx = ceiling $ dMin / niceStep
            endIdx = floor $ dMax / niceStep

        minMax :: (Point num -> num) -> Rect num -> (num, num)
        minMax dim rect = (dim . topLeft $ rect, dim . bottomRight $ rect)

    style =
        ".plot" ? do
            "text" ? do
                "fill" -: "currentColor"
                Clay.userSelect Clay.none
                Clay.opacity 0.75
                Clay.fontSize $ Clay.em 0.8
