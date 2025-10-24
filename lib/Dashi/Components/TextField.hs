{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (Background, fullWidth, label, name, span_, value, var)
import Clay.Elements qualified as Clay
import Dashi.Components.Message (Message (..), MessageSize (FormMessage))
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Dashi.Util (fromText)
import Data.Aeson qualified as Aeson
import Miso (MisoString, text)
import Miso.Html.Element (div_, input_, label_, span_)
import Miso.Html.Property (class_, for_, name_)
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

data TextField = TextField
    { label :: MisoString
    , name :: MisoString
    , value :: Maybe MisoString
    , isValid :: Bool
    , messages :: [(Appearance, MisoString)]
    }

instance Widget TextField where
    widget' attrs TextField{..} =
        div_ [class_ "text-field"] $
            label_
                labelFor
                [ span_ (class_ "label" : labelRequired) [text label]
                , input_ (name_ name : attrs)
                ]
                : [ widget Message{size = FormMessage, title = Nothing, ..}
                  | (appearance, Just -> secondary) <- messages
                  ]
      where
        labelFor =
            case findProp "id" attrs of
                Just (Aeson.String cssId) -> [for_ (fromText cssId)]
                _ -> []
        labelRequired = [class_ "required" | hasRequired attrs]

    style = do
        ":root" ? tokenDecl @Background
        ".text-field" ? do
            (self <> Clay.label <> ".label" <> input) ? do
                display block
                fullWidth
            ".label" ? do
                fontWeight $ weight 600
                fontSize $ pct 85
                marginBottom . token $ Space XSmall
                ".required" <> after & do
                    fontWeight $ weight 400
                    content $ stringContent "*"
                    color' $ Text Danger
                    marginLeft . token $ Space XSmall
            input ? do
                focusable
                border (var "border-width" []) solid (token InputBorder)
                paddingAll' XSmall
                borderRadiusAll' Small
                transition "background" (sec 0.1) easeOut 0
                backgroundColor' $ Background DefaultState
                hover & backgroundColor' (Background HoveredState)
                active & backgroundColor' (Background PressedState)
                ":user-invalid" & ":not(:focus-visible)" & borderColor' InputBorderDanger
