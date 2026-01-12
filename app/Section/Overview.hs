{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Overview where

import Dashi.Components.Heading
import Dashi.Prelude hiding (view)
import Dashi.Style.Tokens
import Miso hiding (update, view)
import Miso.Html.Element (a_, p_, section_)
import Miso.Html.Property (href_)

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
        , p_ [] [text "Dashi is a design system for dashboards, built on top of ", a_ [href_ "https://haskell-miso.org/"] [text "the Miso frontend framework"], text " using ", a_ [href_ "https://haskell.org"] [text "the Haskell programming language"], text "."]
        , p_ [] [text "A design system is a set of building blocks and standards that help keep the look and feel of products and experiences consistent. Think of it as a blueprint, offering a unified language and structured framework that guides teams through the complex process of creating digital products. A design system can assist in reducing the amount of time spent recreating elements and patterns while designing and building products and interfaces at scale."]
        ]
