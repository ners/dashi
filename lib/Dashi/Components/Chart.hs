{-# LANGUAGE AllowAmbiguousTypes #-}

module Dashi.Components.Chart
    ( module Dashi.Components.Chart
    , module Graphics.Rendering.Chart.Easy
    )
where

import Dashi.Style.Colour (convertAlphaColor)
import Dashi.Util (ishow)
import Data.Colour qualified
import Data.Colour.SRGB qualified
import Diagrams.Prelude qualified as Diagrams
import Graphics.Color.Model (Alpha)
import Graphics.Color.Space (Linearity (NonLinear))
import Graphics.Color.Space.OKLAB.LCH
import Graphics.Color.Space.RGB.SRGB
import Graphics.Rendering.Chart.Backend.Diagrams qualified as Chart
import Graphics.Rendering.Chart.Easy
import Graphics.Rendering.Chart.Easy qualified as Chart
import Miso
import Miso.Canvas qualified as Canvas
import Miso.Canvas.Diagrams qualified as Diagrams
import Miso.Mathml.Property (height_, width_)
import System.IO.Unsafe (unsafePerformIO)
import Prelude

chartColour :: Iso' (Color (Alpha OKLCH) Double) (Data.Colour.AlphaColour Double)
chartColour = iso from' to'
  where
    to' :: Data.Colour.AlphaColour Double -> Color (Alpha OKLCH) Double
    to' c = convertAlphaColor @_ @(SRGB 'NonLinear) $ ColorSRGBA r g b a
      where
        a = Data.Colour.alphaChannel c
        Data.Colour.SRGB.RGB r g b = Data.Colour.SRGB.toSRGB $ c `Data.Colour.over` Data.Colour.black
    from' :: Color (Alpha OKLCH) Double -> Data.Colour.AlphaColour Double
    from' (convertAlphaColor @(SRGB 'NonLinear) -> ColorSRGBA r g b a) =
        Data.Colour.withOpacity (Data.Colour.SRGB.sRGB r g b) a

chart :: (Chart.PlotValue x, Chart.PlotValue y) => Int -> Int -> Chart.EC (Chart.Layout x y) () -> View model action
chart w h =
    Canvas.canvas
        [ width_ (ishow w)
        , height_ (ishow h)
        ]
        (const $ pure ())
        . const
        . Diagrams.renderDia Diagrams.Canvas (Diagrams.CanvasOptions Diagrams.absolute)
        . fst
        . Chart.runBackendR env
        . Chart.toRenderable
        . (& layout_foreground .~ ColorOKLCHA 0.7 0 0 1 ^. chartColour)
        . (& layout_background .~ solidFillStyle transparent)
        . Chart.execEC
        . (Chart.liftCState (Chart.colors .= cycle chartColours) *>)
  where
    env :: Chart.DEnv Double
    env = unsafePerformIO $ Chart.defaultEnv Chart.vectorAlignmentFns (fromIntegral w) (fromIntegral h)
    chartColours = [ColorOKLCHA 0.7 0.16 h' 1 ^. chartColour | h' <- [250, 320, 150, 30]]
