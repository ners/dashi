{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (Background, fullWidth, label, span_, var)
import Dashi.Components.Util
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Dashi.Util (fromText)
import Data.Aeson qualified as Aeson
import Miso (Attribute, MisoString, View, text)
import Miso.Html.Element (input_, label_, span_)
import Miso.Html.Property (class_, for_)
import Prelude

newtype Background = Background InputState
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token Background where
    tokenName (Background state) = "text-field-background-" <> tokenName state
    tokenAttr (Background state) = tokenAttr state

instance ValueToken Background where
    type ValueType Background = Color
    tokenValue (Background DefaultState) = parse "#FFF"
    tokenValue (Background HoveredState) = parse "#F8F8F8"
    tokenValue (Background PressedState) = parse "#FFF"

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
                color' $ Text Danger
                marginLeft . token $ Space XSmall
        input ? do
            display block
            fullWidth
            border (var "border-width" []) solid (token InputBorder)
            paddingAll' XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.1) easeOut 0
            backgroundColor' $ Background DefaultState
            hover & backgroundColor' (Background HoveredState)
            active & backgroundColor' (Background PressedState)
