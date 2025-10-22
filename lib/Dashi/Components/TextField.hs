{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (fullWidth, label, span_, var)
import Dashi.Components.Util
import Dashi.Style.Tokens
import Dashi.Style.Util
import Dashi.Util (fromText)
import Data.Aeson qualified as Aeson
import Miso (Attribute, MisoString, View, text)
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Property (class_, for_)
import Prelude

view :: [Attribute action] -> MisoString -> View model action
view attrs label =
    label_
        ([class_ "text-field"] <> labelFor)
        [ span_ (class_ "label" : labelRequired) [text label]
        , input_ attrs
        ]
  where
    labelFor =
        case findProp "id" attrs of
            Just (Aeson.String cssId) -> [for_ (fromText cssId)]
            _ -> []
    labelRequired = [class_ "required" | isRequired attrs]

style :: Css
style = do
    ".text-field" ? do
        display block
        ".label" ? do
            display block
            fullWidth
            fontWeight $ weight 600
            fontSize $ pct 85
            marginBottom . token $ Space XSmall
            ".required" <> after & do
                fontWeight $ weight 400
                content $ stringContent "*"
                color' TextDanger
                marginLeft . token $ Space XSmall
        input ? do
            display block
            fullWidth
            border (var "border-width" []) solid (token BorderInput)
            paddingAll' XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.1) easeOut 0
            backgroundColor' $ BackgroundInput DefaultState
            hover & backgroundColor' (BackgroundInput HoveredState)
            active & backgroundColor' (BackgroundInput PressedState)
