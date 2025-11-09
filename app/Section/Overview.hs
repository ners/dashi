{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Overview where

import Dashi.Components.Heading
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (p_, section_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

overview :: Component parent Model Action
overview = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View model action
view Model =
    section_
        []
        [ widget $ Heading Large "Overview"
        , p_ [] [text "A design system is a collection of pre-built, reusable assets—components, patterns, guidance, and code—that allows its users to build consistent digital experiences faster. By using the pre-built and universal assets of Carbon, the time teams spend designing and building is minimized. Instead of building and re-building basic elements, they can spend that time customizing their products to address specific client use cases."]
        , p_ [] [text "This design system is named Dashi because it is particularly optimised for building beautiful dashboards."]
        ]
