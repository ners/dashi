{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Plot where

import Control.Lens.Operators ((&~), (.=))
import Dashi.Components.Heading
import Dashi.Components.Plot qualified as Plot
import Dashi.Components.Widget
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

plot :: Component parent Model Action
plot = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Plot"
        , p_ [] [text "Plots offer a way to visualise data sets in an intuitive, easy to understand way."]
        , div_ [] . pure . Plot.plot 800 800 $
            Plot.r2Axis &~ do
                Plot.title . Plot.hidden .= True
                Plot.linePlot' $ signal [0, 0.5 .. 400]
        ]
  where
    signal :: [Double] -> [(Double, Double)]
    signal xs = [(x, (sin (x * pi / 45) + 1) / 2 * sin (x * pi / 5)) | x <- xs]
