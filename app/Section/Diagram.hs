{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Diagram where

import Dashi.Components.Chart qualified as Chart
import Dashi.Components.Heading
import Dashi.Components.Widget
import Dashi.Style.Colour qualified as Colour.Scheme
import Dashi.Style.Tokens
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
        , div_ [] . pure . Chart.chart Colour.Scheme.Dark 740 300 $ do
            Chart.plot (Chart.line "amplitude modulation" [signal [0, (0.5) .. 400]])
            Chart.plot (Chart.points "points" (signal [0, 7 .. 400]))
        ]
  where
    signal :: [Double] -> [(Double, Double)]
    signal xs = [(x, (sin (x * pi / 45) + 1) / 2 * (sin (x * pi / 5))) | x <- xs]
