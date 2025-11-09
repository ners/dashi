{-# LANGUAGE AllowAmbiguousTypes #-}

module Dashi.Components.Chart (
    module Dashi.Components.Chart,
    module Graphics.Rendering.Chart.Easy,
) where

import Dashi.Style.Colour (convertAlphaColor)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens (Appearance (Default), ValueToken (tokenValue))
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

toChartColour :: Color (Alpha OKLCH) Double -> Data.Colour.AlphaColour Double
toChartColour (convertAlphaColor @(SRGB 'NonLinear) -> ColorSRGBA r g b a) =
    Data.Colour.withOpacity (Data.Colour.SRGB.sRGB r g b) a

chart :: (Chart.PlotValue x, Chart.PlotValue y) => Colour.Scheme -> Int -> Int -> Chart.EC (Chart.Layout x y) () -> View model action
chart scheme w h =
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
        . (& layout_foreground .~ (toChartColour . Colour.getLightDark scheme . tokenValue . Colour.Text) Default)
        . (& layout_background .~ solidFillStyle transparent)
        . Chart.execEC
  where
    env :: Chart.DEnv Double
    env = unsafePerformIO $ Chart.defaultEnv Chart.vectorAlignmentFns (fromIntegral w) (fromIntegral h)
