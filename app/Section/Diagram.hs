{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Diagram where

import Control.Lens.Operators ((.=))
import Dashi.Components.Chart qualified as Chart
import Dashi.Components.Heading
import Dashi.Components.Widget
import Dashi.Style.Tokens
import Dashi.Util (ishow)
import Data.Bifunctor (Bifunctor (second))
import Data.Foldable (for_)
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

diagram :: Component parent Model Action
diagram = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Diagram"
        , p_ [] [text "Diagrams offer a way to visualise data sets in an intuitive, easy to understand way."]
        , div_ [] . pure . Chart.chart 800 300 $ do
            Chart.layout_legend .= Nothing
            for_ [0 .. 3] \i -> do
                Chart.plot $ Chart.line ("signal " <> ishow @Int (succ . round $ i)) [second (i +) <$> signal [0, (0.5) .. 400]]
        ]
  where
    signal :: [Double] -> [(Double, Double)]
    signal xs = [(x, (sin (x * pi / 45) + 1) / 2 * (sin (x * pi / 5))) | x <- xs]
