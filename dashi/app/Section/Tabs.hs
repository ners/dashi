{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Tabs where

import Dashi.Components.Heading
import Dashi.Components.Tabs
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (div_, p_, section_)

newtype Tab = Tab Int
    deriving stock (Eq, Show)

newtype Model = Model {tab :: Tab}
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model (Tab 1)

data Action
    = NoOp
    | SelectTab Tab

tabs :: Component parent props Model Action
tabs = component initialModel update view

update :: Action -> Effect parent props Model Action
update NoOp = pure ()
update (SelectTab tab) = #tab .= tab

view :: props -> Model -> View Model Action
view _ Model{..} =
    section_
        []
        [ widget $ Heading Large "Tabs"
        , p_
            []
            [ text
                "Tabs are used to organise content by grouping similar information on the same page."
            ]
        , div_
            []
            [ widget @(Tabs Tab Model Action)
                Tabs
                    { tabs = Tab <$> [1, 2, 3]
                    , label = pure . text . ishow
                    , selected = (== tab)
                    , onSelect = SelectTab
                    }
            ]
        , div_ [] [text $ "Contents of " <> ishow tab]
        ]
