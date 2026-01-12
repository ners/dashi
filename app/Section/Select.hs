{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Select where

import Dashi.Components.Form (FormField (..))
import Dashi.Components.Heading
import Dashi.Components.Select
import Dashi.Components.Widget
import Dashi.Style.Tokens
import Dashi.Util (uncapitalise)
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (div_, p_, section_)
import Miso.String qualified as MisoString
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

select :: Component parent Model Action
select = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Select"
        , p_ [] [text "Select allows users to make a single selection or multiple selections from a list of options."]
        , div_
            []
            [ widget @(FormField (Select MisoString Model Action) Model Action)
                FormField
                    { legend = [text "Which continent do you live on?"]
                    , required = False
                    , field =
                        Select
                            { name = "select"
                            , options = ["Africa", "Asia", "Europe", "North America", "South America", "Antarctica", "Australia"]
                            , selected = const False
                            , value = MisoString.intercalate "-" . fmap uncapitalise . MisoString.words
                            , label = pure . text
                            }
                    , messages = []
                    }
            ]
        ]
