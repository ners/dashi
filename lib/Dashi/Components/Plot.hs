{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Plot where

import Clay ((-:), (?))
import Clay qualified
import Dashi.Prelude hiding (none, (&))
import Dashi.Style.Colour (Alpha)
import Dashi.Util (formatFloat)
import Data.List qualified as List
import Graphics.Color.Space.OKLAB.LCH
import Miso.Html.Property qualified as Svg
import Miso.String qualified as MisoString
import Miso.Svg qualified
import Miso.Svg qualified as Svg
import Miso.Svg.Property qualified as Svg

data PlotType = LinePlot | BarPlot
    deriving stock (Eq, Show)

data Series = Series
    { colour :: Color (Alpha OKLCH) Double
    , values :: [(Double, Double)]
    }
    deriving stock (Eq, Show)

data PaddingAmount
    = Relative Double
    | Absolute Int

absolutePadding :: Double -> PaddingAmount -> Double
absolutePadding total (Relative r) = total * r
absolutePadding _ (Absolute a) = fromIntegral a

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
    { plotType :: PlotType
    , width :: Int
    , height :: Int
    , padding :: Maybe Padding
    , showAxes :: Bool
    , showGrid :: Bool
    , series :: [Series]
    }

instance Widget Plot model action where
    widget' attrs Plot{..} =
        Svg.svg_
            ( Svg.width_ (toMisoString width)
                : Svg.height_ (toMisoString height)
                : Svg.viewBox_ (MisoString.unwords . fmap toMisoString $ [0, 0, width, height])
                : Svg.className "plot"
                : attrs
            )
            . mconcat
            $ [ if showGrid then gridElements else []
              , if showAxes then axisElements else []
              , plotElements
              ]
      where
        resolvePadding :: Double -> Double -> Maybe Padding -> (Double, Double, Double, Double)
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
        (paddingTop, paddingRight, paddingBottom, paddingLeft) = resolvePadding width' height' padding
        width' = fromIntegral width
        height' = fromIntegral height

        (domainX, domainY) = ((xMin, xMax), (yMin, yMaxBuffer))
          where
            allPoints = concatMap values series
            (xs, ys) = unzip allPoints
            rawXMin = minimum xs
            rawXMax = maximum xs

            -- Bar Chart Adjustment:
            -- If we have bars at x=0, we want the axis to go from -0.5 to make room.
            (xMin, xMax) = case plotType of
                BarPlot -> (rawXMin - 0.5, rawXMax + 0.5)
                LinePlot -> (rawXMin, rawXMax)

            yMin = minimum (0 : ys)
            yMax = maximum ys
            -- Add a tiny buffer to Y max so lines don't clip at the very top
            yMaxBuffer = if yMax == 0 then 1 else yMax * 1.05

        scale :: (Double, Double) -> (Double, Double) -> Double -> Double
        scale (dMin, dMax) (rMin, rMax) x
            | dMax == dMin = rMin -- Avoid division by zero
            | otherwise = rMin + (x - dMin) * (rMax - rMin) / (dMax - dMin)

        scaleX = scale domainX (paddingLeft, width' - paddingRight)
        scaleY = scale domainY (height' - paddingBottom, paddingTop)

        ticksX =
            case plotType of
                LinePlot -> calculateTicks domainX $ width `div` 100
                BarPlot -> List.nub . List.sort $ fst <$> concatMap values series
        ticksY = calculateTicks domainY $ height `div` 100

        plotElements = case plotType of
            LinePlot -> renderLine <$> series
            BarPlot -> renderBars

        axisColour :: Double -> MisoString
        axisColour = toMisoString . ColorOKLCHA 0.7 0 0

        -- "Nice Numbers" algorithm to find human-readable tick values
        calculateTicks :: (Double, Double) -> Int -> [Double]
        calculateTicks (dMin, dMax) targetCount
            | dMin >= dMax = [dMin]
            | otherwise =
                let range = dMax - dMin
                    roughStep = range / fromIntegral targetCount

                    -- Calculate magnitude of the step (power of 10)
                    exponent = floor @_ @Int (logBase 10 roughStep)
                    fraction = roughStep / (10 ^^ exponent)

                    -- Round to nearest nice step (1, 2, 5, 10)
                    niceFraction
                        | fraction < 1.5 = 1
                        | fraction < 3.5 = 2
                        | fraction < 7.5 = 5
                        | otherwise = 10

                    niceStep = niceFraction * (10 ^^ exponent)

                    -- Calculate start and end indices
                    startIdx, endIdx :: Int
                    startIdx = ceiling $ dMin / niceStep
                    endIdx = floor $ dMax / niceStep
                 in (niceStep *) . fromIntegral <$> [startIdx .. endIdx]

        renderLine :: Series -> View model action
        renderLine Series{..} =
            let
                mkPoint :: (Double, Double) -> MisoString
                mkPoint (x, y) = MisoString.unwords . fmap formatFloat $ [scaleX x, scaleY y]
                dAttr = case values of
                    [] -> ""
                    (p : ps) -> mconcat $ "M " : mkPoint p : ((" L " <>) . mkPoint <$> ps)
             in
                Miso.Svg.path_
                    [ Svg.d_ dAttr
                    , Svg.fill_ "none"
                    , Svg.stroke_ $ toMisoString colour
                    , Svg.strokeWidth_ "2"
                    , Svg.strokeLinecap_ "round"
                    ]

        renderBars :: [View model action]
        renderBars = concatMap drawSeries (zip [0 ..] series)
          where
            -- For overlaid time series in bar charts, we often render them side-by-side (grouped)
            -- or strictly overlaid with opacity. Here we implement "Side by Side" grouping for clarity.

            nSeries = fromIntegral (length series)
            (dXMin, dXMax) = domainX
            dataSpan = dXMax - dXMin
            -- Calculate width of one logical "slot" on the X axis
            -- We assume data points are integers 0, 1, 2... for bars usually.
            -- If they aren't, this width calc might need adjustment.
            slotWidth = width' / (if dataSpan == 0 then 1 else dataSpan + 1)
            barWidth = (slotWidth * 0.8) / nSeries

            drawSeries :: (Int, Series) -> [View model action]
            drawSeries (idx, s) =
                [ Svg.rect_
                    [ Svg.x_ (toMisoString $ scaleX x - (slotWidth * 0.4) + (barWidth * fromIntegral idx))
                    , Svg.y_ (toMisoString $ scaleY y)
                    , Svg.width_ (toMisoString barWidth)
                    , Svg.height_ (toMisoString $ abs (scaleY 0 - scaleY y)) -- Height is distance from Y=0 to Y=Value
                    , Svg.fill_ (toMisoString $ colour s)
                    ]
                | (x, y) <- values s
                ]

        gridElements :: [View model action]
        gridElements = vertLines <> horizLines
          where
            vertLines =
                case plotType of
                    BarPlot -> []
                    LinePlot -> ticksX <&> \(scaleX -> tickX) -> gridLine (tickX, paddingTop) (tickX, height' - paddingBottom)
            horizLines = ticksY <&> \(scaleY -> tickY) -> gridLine (paddingLeft, tickY) (width' - paddingRight, tickY)
            gridLine :: (Double, Double) -> (Double, Double) -> View model action
            gridLine (x1, y1) (x2, y2) =
                Svg.line_
                    [ Svg.x1_ $ toMisoString x1
                    , Svg.y1_ $ toMisoString y1
                    , Svg.x2_ $ toMisoString x2
                    , Svg.y2_ $ toMisoString y2
                    , Svg.stroke_ $ axisColour 0.5
                    , Svg.strokeWidth_ "1"
                    ]

        axisElements :: [View model action]
        axisElements = [yAxis, xAxis] <> concatMap mkTickX ticksX <> concatMap mkTickY ticksY
          where
            yAxis =
                Svg.line_
                    [ Svg.x1_ $ toMisoString paddingLeft
                    , Svg.y1_ $ toMisoString paddingTop
                    , Svg.x2_ $ toMisoString paddingLeft
                    , Svg.y2_ $ toMisoString (height' - paddingBottom)
                    , Svg.stroke_ $ axisColour 1
                    , Svg.strokeWidth_ "1"
                    ]

            xAxis =
                Svg.line_
                    [ Svg.x1_ $ toMisoString paddingLeft
                    , Svg.y1_ $ toMisoString (height' - paddingBottom)
                    , Svg.x2_ $ toMisoString (width' - paddingRight)
                    , Svg.y2_ $ toMisoString (height' - paddingBottom)
                    , Svg.stroke_ $ axisColour 1
                    , Svg.strokeWidth_ "1"
                    ]

            mkTickX val =
                let pos = scaleX val
                 in [ Svg.line_
                        [ Svg.x1_ $ toMisoString pos
                        , Svg.y1_ $ toMisoString (height' - paddingBottom)
                        , Svg.x2_ $ toMisoString pos
                        , Svg.y2_ $ toMisoString (height' - paddingBottom + 5)
                        , Svg.stroke_ $ axisColour 0.5
                        ]
                    , Svg.text_
                        [ Svg.x_ $ toMisoString pos
                        , Svg.y_ $ toMisoString (height' - paddingBottom + 15)
                        , Svg.textAnchor_ "middle"
                        ]
                        [text $ formatFloat val]
                    ]

            mkTickY val =
                let pos = scaleY val
                 in [ Svg.line_
                        [ Svg.x1_ $ toMisoString (paddingLeft - 5)
                        , Svg.y1_ $ toMisoString pos
                        , Svg.x2_ $ toMisoString paddingLeft
                        , Svg.y2_ $ toMisoString pos
                        , Svg.stroke_ $ axisColour 1
                        ]
                    , Svg.text_
                        [ Svg.x_ $ toMisoString (paddingLeft - 8)
                        , Svg.y_ $ toMisoString (pos + 3)
                        , Svg.textAnchor_ "end"
                        ]
                        [text (formatFloat val)]
                    ]

    style =
        ".plot" ? do
            "text" ? do
                "fill" -: "currentColor"
                Clay.userSelect Clay.none
                Clay.opacity 0.75
                Clay.fontSize $ Clay.em 0.8
