{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
module Dashi.Layout.Page where

import Clay hiding (not, main_, aside, action)
import Clay qualified
import Clay.Media (minDeviceWidth)
import Dashi.Style.Util
import Data.List qualified as List
import Prelude hiding (all, rem)
import Dashi.Components.Widget
import Miso (View)
import Miso.Html.Property (id_)
import Miso.Html.Element (header_, div_, main_, aside_, nav_)
import Data.Maybe (catMaybes)

data Page model action = Page
    { banner :: Maybe [View model action]
    , topBar :: Maybe [View model action]
    , sideNav :: Maybe [View model action]
    , main :: [View model action]
    , aside :: Maybe [View model action]
    }

instance Widget (Page model action) model action where
    widget' attrs Page{..} =
        div_ (id_ "page" : attrs) . catMaybes $
            [ header_ [] <$> topBar
            , nav_ [] <$> sideNav
            , pure $ main_ [] main
            , aside_ [] <$> aside
            ]
    style = do
        "#page" ? do
            display grid
            minHeight $ vh 100
            gridTemplateAreas [["banner"], ["top-bar"], ["main"], ["aside"]]
            "grid-template-rows" -: "auto auto 1fr auto"
            "grid-template-columns" -: "minmax(0,1fr)"
            query all [minDeviceWidth $ rem 64] do
                gridTemplateAreas
                    [ List.replicate 3 "banner"
                    , List.replicate 3 "top-bar"
                    , ["side-nav", "main", "aside"]
                    ]
                "grid-template-rows" -: "auto auto 3fr"
                "grid-template-columns" -: "auto minmax(0,1fr) auto"
            query all [minDeviceWidth $ rem 90] do
                gridTemplateAreas
                    [ List.replicate 4 "banner"
                    , List.replicate 4 "top-bar"
                    , ["side-nav", "main", "aside", "panel"]
                    ]
                "grid-template-rows" -: "auto auto 3fr"
                "grid-template-columns" -: "auto minmax(0,1fr) auto auto"
            header ? do
                "grid-area" -: "top-bar"
            nav ? do
                "grid-area" -: "side-nav"
            Clay.main_ ? do
                "grid-area" -: "main"
                "isolation" -: "isolate"
                overflow auto
                query all [minDeviceWidth $ rem 64] do
                    "isolation" -: "auto"
                    position sticky
