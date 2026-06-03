{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Range where

import Dashi.Components.Heading
import Dashi.Components.Range
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (p_, section_)

newtype Model = Model {value :: Int}
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model{value = 110}

data Action
    = NoOp
    | SetValue Int

range :: Component parent props Model Action
range = component initialModel update view

update :: Action -> Effect parent props Model Action
update NoOp = pure ()
update (SetValue v) = #value .= v

view :: props -> Model -> View Model Action
view _ Model{..} =
    section_
        []
        [ widget $ Heading Large "Range"
        , p_ [] [text "A range lets users choose an approximate value on a slider."]
        , widget Range{value, step = 10, min = 0, max = 200, onChange = SetValue}
        ]
