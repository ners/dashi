module Dashi.Layout.Page where

import Clay
import Clay.Media (minDeviceWidth)
import Dashi.Style.Util
import Data.List qualified as List
import Prelude hiding (all, rem)

style :: Css
style = do
    body ? do
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
        main_ ? do
            "grid-area" -: "main"
            "isolation" -: "isolate"
            overflow auto
            query all [minDeviceWidth $ rem 64] do
                "isolation" -: "auto"
                position sticky
