module Dashi.Components.TextField where

import Clay (Css, active, block, border, display, easeOut, em, fontSize, fontWeight, hover, input, marginBottom, sec, solid, transition, weight, (&), (?))
import Dashi.Components.Util
import Dashi.Style.Tokens
import Dashi.Style.Util (backgroundColor', borderRadiusAll', fullWidth, paddingYX', token, var)
import Dashi.Util (fromText)
import Data.Aeson qualified as Aeson
import Miso (Attribute, MisoString, View, text)
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Property (class_, for_)
import Prelude

textField :: [Attribute action] -> MisoString -> View model action
textField attrs l =
    label_
        ([class_ "text-field"] <> labelFor)
        [ span_ [class_ "label"] [text l]
        , input_ attrs
        ]
  where
    labelFor =
        case findProp "id" attrs of
            Just (Aeson.String cssId) -> [for_ (fromText cssId)]
            _ -> []

style :: Css
style = do
    ".text-field" ? do
        display block
        ".label" ? do
            display block
            fullWidth
            fontWeight $ weight 600
            fontSize $ em 0.75
            marginBottom . token $ Space XSmall
        input ? do
            display block
            fullWidth
            border (var "border-width" []) solid (token Border)
            paddingYX' XSmall XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.1) easeOut 0
            backgroundColor' $ BackgroundInput DefaultState
            hover & backgroundColor' (BackgroundInput HoveredState)
            active & backgroundColor' (BackgroundInput PressedState)
