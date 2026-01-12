{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Layout.Page where

import Clay hiding (action, aside, main_, not)
import Clay qualified
import Clay.Media (minDeviceWidth)
import Dashi.Components.Widget
import Dashi.Style.Util
import Data.List qualified as List
import Data.Maybe (catMaybes)
import Miso (View)
import Miso.Html.Element (aside_, div_, header_, nav_)
import Miso.Html.Element qualified as Html
import Miso.Html.Property (id_)
import Prelude hiding (all, rem)

data Page model action = Page
    { banner :: Maybe [View model action]
    , topBar :: Maybe [View model action]
    , sideNav :: Maybe [View model action]
    , main_ :: [View model action]
    , aside :: Maybe [View model action]
    }

instance Widget (Page model action) model action where
    widget' attrs Page{..} =
        div_ (id_ "page" : attrs) . catMaybes $
            [ header_ [] <$> topBar
            , nav_ [] <$> sideNav
            , pure $ Html.main_ [] main_
            , aside_ [] <$> aside
            ]
    style = do
        "#page" ? do
            minHeight $ vh 100
            display grid
            gridTemplateAreas [["top-bar"], ["main"], ["aside"]]
            "grid-template-rows" -: "auto 1fr auto"
            query all [minDeviceWidth $ rem 64] do
                gridTemplateAreas
                    [ List.replicate 2 "top-bar"
                    , ["side-nav", "main"]
                    ]
                "grid-template-rows" -: "auto 1fr"
                "grid-template-columns" -: "auto 1fr"
                has Clay.aside & do
                    gridTemplateAreas
                        [ List.replicate 3 "top-bar"
                        , ["side-nav", "main", "aside"]
                        ]
                    "grid-template-columns" -: "auto 1fr auto"
                nav ? do
                    "grid-area" -: "side-nav"
            header ? do
                "grid-area" -: "top-bar"
            nav ? do
                "grid-area" -: "main"
            Clay.main_ ? do
                "grid-area" -: "main"
                "isolation" -: "isolate"
                overflow auto
                query all [minDeviceWidth $ rem 64] do
                    "isolation" -: "auto"
                    position sticky
