module Dashi.Components.Chart (
    module Dashi.Components.Chart,
    module Graphics.Rendering.Chart.Easy,
) where

import Dashi.Util (ishow)
import Diagrams.Prelude qualified as Diagrams
import Graphics.Rendering.Chart.Backend.Diagrams qualified as Chart
import Graphics.Rendering.Chart.Easy
import Graphics.Rendering.Chart.Easy qualified as Chart
import Miso
import Miso.Canvas qualified as Canvas
import Miso.Canvas.Diagrams qualified as Diagrams
import Miso.Mathml.Property (height_, width_)
import System.IO.Unsafe (unsafePerformIO)
import Prelude

chart :: (Chart.PlotValue x, Chart.PlotValue y) => Int -> Int -> Chart.EC (Chart.Layout x y) () -> View model action
chart w h =
    Canvas.canvas
        [width_ (ishow w), height_ (ishow h)]
        (const $ pure ())
        . const
        . Diagrams.renderDia Diagrams.Canvas (Diagrams.CanvasOptions Diagrams.absolute)
        . fst
        . Chart.runBackendR env
        . Chart.toRenderable
        . Chart.execEC
  where
    env :: Chart.DEnv Double
    env = unsafePerformIO $ Chart.defaultEnv Chart.vectorAlignmentFns (fromIntegral w) (fromIntegral h)
