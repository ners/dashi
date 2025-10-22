module Dashi.Components.Spinner where

import Dashi.Components.Widget
import Miso.Svg.Element
import Miso.Svg.Property
import Prelude

data Spinner = Spinner

instance Widget Spinner where
    widget' attrs Spinner =
        svg_
            ( [ width_ "24"
              , height_ "24"
              , stroke_ "currentColor"
              , viewBox_ "0 0 24 24"
              , class_' "spinner"
              ]
                <> attrs
            )
            [ style_ [] [".spinner1{transform-origin:center;animation:spinner3 2s linear infinite}.spinner1 circle{stroke-linecap:round;animation:spinner2 1.5s ease-in-out infinite}@keyframes spinner3{100%{transform:rotate(360deg)}}@keyframes spinner2{0%{stroke-dasharray:0 150;stroke-dashoffset:0}47.5%{stroke-dasharray:42 150;stroke-dashoffset:-16}95%,100%{stroke-dasharray:42 150;stroke-dashoffset:-59}}"]
            , g_
                [class_' "spinner1"]
                [ circle_
                    [ cx_ "12"
                    , cy_ "12"
                    , r_ "9.5"
                    , fill_ "none"
                    , strokeWidth_ "3"
                    ]
                ]
            ]
