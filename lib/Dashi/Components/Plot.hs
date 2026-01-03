module Dashi.Components.Plot
    ( module Dashi.Components.Plot
    , module Plots
    , module Plots.Axis
    , module Plots.Types.Line
    , module Diagrams.Prelude
    , module Miso.Canvas.Diagrams
    )
where

import Dashi.Style.Colour
import Data.Colour qualified
import Data.Colour.SRGB qualified
import Diagrams.Prelude (V2 (..), dims2D, mkSizeSpec2D)
import Diagrams.Prelude qualified as Diagrams
import Graphics.Color.Space (Linearity (NonLinear))
import Graphics.Rendering.Chart.Easy
import Miso hiding ((!!))
import Miso.Canvas qualified as Canvas
import Miso.Canvas.Diagrams (Canvas)
import Miso.Canvas.Diagrams qualified as Diagrams
import Miso.Mathml.Property (height_, width_)
import Plots
import Plots.Axis
import Plots.Axis.Line
import Plots.Types.Line
import Prelude

chartColour :: Iso' (Color OKLCH Double) (Data.Colour.Colour Double)
chartColour = iso from' to'
  where
    to' :: Data.Colour.Colour Double -> Color OKLCH Double
    to' c = convertColor @_ @(SRGB 'NonLinear) $ ColorSRGB r g b
      where
        Data.Colour.SRGB.RGB r g b = Data.Colour.SRGB.toSRGB c
    from' :: Color OKLCH Double -> Data.Colour.Colour Double
    from' (convertColor @(SRGB 'NonLinear) -> ColorSRGB r g b) = Data.Colour.SRGB.sRGB r g b

chartColourA :: Iso' (Color (Alpha OKLCH) Double) (Data.Colour.AlphaColour Double)
chartColourA = iso from' to'
  where
    to' :: Data.Colour.AlphaColour Double -> Color (Alpha OKLCH) Double
    to' c = convertAlphaColor @_ @(SRGB 'NonLinear) $ ColorSRGBA r g b a
      where
        a = Data.Colour.alphaChannel c
        Data.Colour.SRGB.RGB r g b = Data.Colour.SRGB.toSRGB $ c `Data.Colour.over` Data.Colour.black
    from' :: Color (Alpha OKLCH) Double -> Data.Colour.AlphaColour Double
    from' (convertAlphaColor @(SRGB 'NonLinear) -> ColorSRGBA r g b a) =
        Data.Colour.withOpacity (Data.Colour.SRGB.sRGB r g b) a

plot :: Int -> Int -> Axis Canvas V2 Double -> View model action
plot w h =
    Canvas.canvas
        [ width_ $ toMisoString w
        , height_ $ toMisoString h
        ]
        (const $ pure ())
        . const
        . Diagrams.renderDia Diagrams.Canvas (Diagrams.CanvasOptions Diagrams.absolute)
        -- . Diagrams.frame (-40)
        . renderAxis
        . (plotColour .~ (chartColours !! 2))
        . (axes . traverse . axisLineStyle %~ Diagrams.lcA transparent)
        . (axes . traverse . axisLabel %~ Diagrams.fcA (fg 1))
        . (titleStyle %~ Diagrams.fcA (fg 1))
        . (title . hidden .~ True)
        . (xAxis . axisExtend .~ noExtend)
        . (gridLinesStyle %~ Diagrams.lcA (fg 0.2))
        . (ticksVisible .~ False)
        . (tickLabelStyle %~ Diagrams.fcA (fg 0.7))
        . (tickLabelStyle . Diagrams._fontSize %~ (* 0.75))
        . (tickLabelGap %~ (* 0.5))
  where
    -- . (xAxis . renderSize .~ Just (fromIntegral $ w - 60))
    -- . (yAxis . renderSize .~ Just (fromIntegral $ h - 60))
    -- . (axes . itraverse %~ (\i -> renderSize .~ Just (fromIntegral w)))
    -- . (axisSize .~ Diagrams.dims2D (fromIntegral w) (fromIntegral h * 1000))
    -- . (scaleAspectRatio ?~ 0.001)
    -- . (renderSize ?~ fromIntegral (max w h - 60))

    chartColours = [ColorOKLCH 0.7 0.16 h' ^. chartColour | h' <- [250, 320, 150, 30]]
    fg a = ColorOKLCHA 0.7 0 0 a ^. chartColourA

-- 1000 1000 -> 0.0061
-- 1000 500 -> 0.014
-- 1000 250 -> 0.035

-- 750 750 -> 0.0061
-- 750 500 -> 0.01

-- 500 1000 -> 0.005
-- 500 500 -> 0.0061
-- 500 250 -> 0.015
