{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.Plot where

import Clay ((-:), (?))
import Clay qualified
import Dashi.Diagram
import Dashi.Prelude hiding (none, transform, (&))
import Dashi.Style.Colour (Alpha)
import Dashi.Util (formatFloat)
import Data.Function ((&))
import Graphics.Color.Space.OKLAB.LCH
import Miso.Html.Property qualified as Svg
import Miso.String qualified as MisoString
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

absolutePadding :: (Fractional num) => num -> PaddingAmount -> num
absolutePadding total (Relative r) = total * realToFrac r
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
        (paddingTop, paddingRight, paddingBottom, paddingLeft) = resolvePadding width' height' padding

        paddedViewBox =
            viewBox
                & #topLeft %~ offsetPoint (+ paddingLeft) (+ paddingTop)
                & #bottomRight %~ offsetPoint (subtract paddingRight) (subtract paddingBottom)

        gridElements :: [View model action]
        gridElements =
            toSVG [Svg.stroke_ (axisColour 0.5), Svg.strokeWidth_ "1"]
                . translateDomain paddedViewBox domain
                $ vertLines
                <> horizLines
          where
            Rect{topLeft = Point{x = left, y = top}, bottomRight = Point{x = right, y = bottom}} = domain
            vertLines =
                case plotType of
                    BarPlot -> []
                    LinePlot -> [Shape $ Line Point{x, y = top} Point{x, y = bottom} | x <- ticksX]
            horizLines = [Shape $ Line Point{x = left, y} Point{x = right, y} | y <- ticksY]

        axisElements :: [View model action]
        axisElements =
            mconcat
                . mconcat
                $ [ mkAxis <$> inViewBox [yAxis, xAxis]
                  , mkTickX <$> ticksX
                  , mkTickY <$> ticksY
                  ]
          where
            Rect{topLeft = Point{x = left, y = top}, bottomRight = Point{x = right, y = bottom}} = domain
            mkAxis :: (ToSVG s num) => s -> [View model action]
            mkAxis = toSVG [Svg.stroke_ (axisColour 1), Svg.strokeWidth_ "1"]
            xAxis, yAxis :: Line Double
            xAxis = Line Point{x = left, y = bottom} Point{x = right, y = bottom}
            yAxis = Line Point{x = left, y = top} Point{x = left, y = bottom}
            inViewBox :: (Shape s Double) => s -> s
            inViewBox = translateDomain paddedViewBox domain

            mkTickX x =
                let
                    p = inViewBox Point{x, y = bottom}
                 in
                    mconcat
                        [ mkAxis $ Line p (offsetPoint id (+ 5) p)
                        , toSVG
                            [Svg.dominantBaseline_ "hanging"]
                            Text
                                { position = offsetPoint id (+ 8) p
                                , anchor = Middle
                                , content = formatFloat x
                                }
                        ]

            mkTickY y =
                let
                    p = inViewBox Point{x = left, y}
                 in
                    mconcat
                        [ mkAxis $ Line (offsetPoint (subtract 5) id p) p
                        , toSVG
                            [Svg.dominantBaseline_ "middle"]
                            Text
                                { position = offsetPoint (subtract 8) id p
                                , anchor = End
                                , content = formatFloat y
                                }
                        ]

        plotElements = mconcat $ case plotType of
            LinePlot ->
                [ toSVG [Svg.stroke_ (toMisoString colour), Svg.strokeWidth_ "2"]
                    . translateDomain paddedViewBox domain
                    $ Path [Point{..} | (x, y) <- values]
                | Series{..} <- series
                ]
            BarPlot -> []

        domain :: Rect Double
        domain = boundingBox . fmap (uncurry Point) $ concatMap values series

        axisColour :: Double -> MisoString
        axisColour = toMisoString . ColorOKLCHA 0.7 0 0

        ticksX = calculateTicks x $ width `div` 100
        ticksY = calculateTicks y $ height `div` 100

        -- "Nice Numbers" algorithm to find human-readable tick values
        calculateTicks :: (Point Double -> Double) -> Int -> [Double]
        calculateTicks dim targetCount
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
          where
            (dMin, dMax) = minMax dim domain

        minMax :: (Point num -> num) -> Rect num -> (num, num)
        minMax dim rect = (dim . topLeft $ rect, dim . bottomRight $ rect)

    style =
        ".plot" ? do
            "text" ? do
                "fill" -: "currentColor"
                Clay.userSelect Clay.none
                Clay.opacity 0.75
                Clay.fontSize $ Clay.em 0.8
