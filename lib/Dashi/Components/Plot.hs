{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Plot where

import Clay ((-:), (?))
import Clay qualified
import Dashi.Diagram
import Dashi.Prelude hiding (none, transform, (&))
import Dashi.Style.Colour (Alpha)
import Data.Foldable (Foldable (toList))
import Data.Function ((&))
import Data.List qualified as List
import Data.List.Extra qualified as List
import Graphics.Color.Space.OKLAB.LCH
import Miso.Html.Property qualified as Svg
import Miso.String qualified as MisoString
import Miso.Svg qualified as Svg
import Miso.Svg.Property qualified as Svg

data PlotType = LinePlot | BarPlot {barWidth :: Double}
    deriving stock (Eq, Show)

data Series = Series
    { strokeColour :: Maybe (Color (Alpha OKLCH) Double)
    , fillColour :: Maybe (Color (Alpha OKLCH) Double)
    , values :: [(Double, Double)]
    , plotType :: PlotType
    }

data PaddingAmount
    = Relative Double
    | Absolute Double

absolutePadding :: (Fractional num) => num -> PaddingAmount -> num
absolutePadding total (Relative r) = total * realToFrac r
absolutePadding _ (Absolute a) = realToFrac a

resolvePadding :: (Fractional num) => num -> num -> Maybe Padding -> (num, num, num, num)
resolvePadding _ _ Nothing = (0, 0, 0, 0)
resolvePadding dX dY (Just SymmetricPadding{..}) =
    let
        pX = absolutePadding dX xPadding
        pY = absolutePadding dY yPadding
     in
        (pY, pX, pY, pX)
resolvePadding dX dY (Just Padding{..}) =
    let
        absX = absolutePadding dX
        absY = absolutePadding dY
     in
        (absY topPadding, absX rightPadding, absY bottomPadding, absX leftPadding)

data Padding
    = SymmetricPadding
        { yPadding :: PaddingAmount
        , xPadding :: PaddingAmount
        }
    | Padding
        { topPadding :: PaddingAmount
        , rightPadding :: PaddingAmount
        , bottomPadding :: PaddingAmount
        , leftPadding :: PaddingAmount
        }

data Plot = Plot
    { width :: Int
    -- ^ The overall width of the canvas, including padding and plot area
    , height :: Int
    -- ^ The overall height of the canvas, including padding and plot area
    , padding :: Maybe Padding
    -- ^ The space from the edge of the canvas to the plot area
    , domainPadding :: Maybe Padding
    -- ^ The space from the edge of the plot area to the series min/max
    , showAxes :: Bool
    {- ^ Whether to render plot axes
    TODO: separate X and Y
    -}
    , showGrid :: Bool
    {- ^ Whether to render plot grid
    TODO: separate X and Y
    -}
    , series :: [Series]
    -- ^ The series to plot
    , showX :: Double -> MisoString
    -- ^ The function to render ticks on the X axis
    , showY :: Double -> MisoString
    -- ^ The function to render ticks on the Y axis
    }

instance Widget Plot model action where
    widget' attrs Plot{..} =
        Svg.svg_
            ( Svg.width_ (toMisoString width)
                : Svg.height_ (toMisoString height)
                : Svg.viewBox_ (MisoString.unwords . fmap toMisoString $ [viewBox.topLeft.x, viewBox.topLeft.y, width, height])
                : Svg.className "plot"
                : attrs
            )
            . mconcat
            $ [ if showGrid then gridElements else []
              , if showAxes then axisElements else []
              , plotElements
              ]
      where
        width', height' :: (Num num) => num
        width' = fromIntegral width
        height' = fromIntegral height

        viewBox :: forall num. (Num num) => Rect num
        viewBox =
            Rect
                { topLeft = Point{x = 0, y = 0}
                , bottomRight = Point{x = width', y = height'}
                }

        paddedViewBox =
            viewBox
                & #topLeft %~ offsetPoint (+ paddingLeft) (const $ viewBox.bottomRight.y - paddingBottom)
                & #bottomRight %~ offsetPoint (subtract paddingRight) (const $ viewBox.topLeft.y + paddingTop)
          where
            (paddingTop, paddingRight, paddingBottom, paddingLeft) = resolvePadding width' height' padding

        gridElements :: [View model action]
        gridElements =
            toSVG [Svg.stroke_ (axisColour 0.5), Svg.strokeWidth_ "1"]
                . translateDomain paddedViewBox domain
                $ [Shape $ Line Point{x, y = top} Point{x, y = bottom} | hasNonBarPlots, x <- ticksX]
                    <> [Shape $ Line Point{x = left, y} Point{x = right, y} | y <- ticksY]
          where
            Rect{topLeft = Point{x = left, y = top}, bottomRight = Point{x = right, y = bottom}} = domain

        axisElements :: [View model action]
        axisElements =
            mconcat
                . mconcat
                $ [ mkAxis <$> inViewBox [yAxis, xAxis]
                  , concatMap mkTickX ticksX
                  , concatMap mkTickY ticksY
                  ]
          where
            Rect{topLeft = Point{x = left, y = top}, bottomRight = Point{x = right, y = bottom}} = domain
            mkAxis :: (ToSVG s num) => s -> [View model action]
            mkAxis = toSVG [Svg.stroke_ (axisColour 1), Svg.strokeWidth_ "1"]
            xAxis, yAxis :: Line Double
            xAxis = Line Point{x = left, y = top} Point{x = right, y = top}
            yAxis = Line Point{x = left, y = top} Point{x = left, y = bottom}
            inViewBox :: (Shape s Double) => s -> s
            inViewBox = translateDomain paddedViewBox domain

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
                p = inViewBox Point{x, y = top}

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
                p = inViewBox Point{x = left, y}

        isBarPlot :: PlotType -> Bool
        isBarPlot BarPlot{} = True
        isBarPlot _ = False

        barPlotSeries :: [Series]
        barPlotSeries = filter (isBarPlot . plotType) series

        barPlotWidth :: PlotType -> Double
        barPlotWidth BarPlot{barWidth} = barWidth
        barPlotWidth _ = 0

        totalBarPlotWidth :: Double
        totalBarPlotWidth = sum $ barPlotWidth . plotType <$> barPlotSeries

        plotElements :: [View model action]
        plotElements =
            mconcat
                [ concatMap (uncurry renderLinePlot) . filter (not . isBarPlot . plotType . fst) $ zip series seriesBoundingBoxes
                , let widths = List.scanl' (+) 0 $ barPlotWidth . plotType <$> barPlotSeries
                   in concatMap (uncurry renderBarPlot) $ zip widths barPlotSeries
                ]

        renderLinePlot :: Series -> Rect Double -> [View model action]
        renderLinePlot Series{..} Rect{..} =
            mconcat . catMaybes $
                [ line <$> strokeColour
                , area <$> fillColour
                ]
          where
            points = uncurry Point <$> values
            bottomRight' = bottomRight{y = domain.topLeft.y}
            bottomLeft' = bottomRight'{x = topLeft.x}
            points' = bottomRight' : bottomLeft' : points
            line colour =
                toSVG
                    [ Svg.fill_ "none"
                    , Svg.stroke_ $ toMisoString colour
                    , Svg.strokeLinecap_ "round"
                    , Svg.strokeWidth_ "2"
                    ]
                    . translateDomain paddedViewBox domain
                    $ Polyline{points}
            area colour =
                toSVG
                    [ Svg.fill_ $ toMisoString colour
                    , Svg.stroke_ "none"
                    ]
                    . translateDomain paddedViewBox domain
                    $ Polygon{points = points'}

        renderBarPlot :: Double -> Series -> [View model action]
        renderBarPlot leftOffset Series{..} =
            flip concatMap values \(x, y) ->
                let
                    left = x + leftOffset - totalBarPlotWidth / 2
                    right = left + barPlotWidth plotType
                 in
                    toSVG
                        [ Svg.fill_ $ maybe "none" toMisoString fillColour
                        , Svg.stroke_ $ maybe "none" toMisoString strokeColour
                        ]
                        . translateDomain paddedViewBox domain
                        $ boundingBoxOfPoints1
                            [ Point{x = left, y}
                            , Point{x = right, y = 0}
                            ]

        seriesBoundingBoxes :: [Rect Double]
        seriesBoundingBoxes = boundingBox . fmap (uncurry Point) . values <$> series

        domain :: Rect Double
        domain =
            d
                & #topLeft %~ offsetPoint (subtract paddingLeft) (subtract paddingBottom)
                & #bottomRight %~ offsetPoint (+ paddingRight) (+ paddingTop)
          where
            d = boundingBox $ seriesBoundingBoxes <> [dummyZero | hasBarPlots]
            dummyZero :: Rect Double
            dummyZero = head seriesBoundingBoxes & #topLeft . #y .~ 0
            (paddingTop, paddingRight, paddingBottom, paddingLeft) = (uncurry resolvePadding $ rectSize d) domainPadding

        axisColour :: Double -> MisoString
        axisColour = toMisoString . ColorOKLCHA 0.7 0 0

        hasBarPlots = any (isBarPlot . plotType) series
        hasNonBarPlots = not $ all (isBarPlot . plotType) series

        ticksX =
            if hasNonBarPlots
                then calculateTicks x $ width `div` 100
                else List.sort . List.nubOrd $ concatMap (toList . fmap fst . values) series
        ticksY = calculateTicks y $ height `div` 100

        -- "Nice Numbers" algorithm to find human-readable tick values
        calculateTicks :: (Point Double -> Double) -> Int -> [Double]
        calculateTicks dim targetCount
            | dMin >= dMax = [dMin]
            | otherwise = (niceStep *) . fromIntegral <$> [startIdx .. endIdx]
          where
            (dMin, dMax) = minMax dim domain
            range = dMax - dMin
            roughStep = range / fromIntegral targetCount

            -- Calculate magnitude of the step (power of 10)
            e = floor @_ @Int (logBase 10 roughStep)
            fraction = roughStep / (10 ^^ e)

            -- Round to nearest nice step (1, 2, 5, 10)
            niceFraction
                | fraction < 1.5 = 1
                | fraction < 3.5 = 2
                | fraction < 7.5 = 5
                | otherwise = 10

            niceStep = niceFraction * (10 ^^ e)

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
