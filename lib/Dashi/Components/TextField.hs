{-# OPTIONS_GHC -Wno-missing-poly-kind-signatures #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (Background, Color, Number, fullWidth, label, name, span_, type_, value, var)
import Dashi.Components.Widget
import Dashi.Style.Colour (LightDark)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Functor ((<&>))
import Data.Maybe (maybeToList)
import Graphics.Color.Space (Alpha)
import Graphics.Color.Space.OKLAB.LCH
import Miso
import Miso.Html.Element (input_, textarea_)
import Miso.Html.Event qualified as Miso
import Miso.Html.Property (name_, type_, value_)
import Prelude

newtype Border = Border InputState
    deriving newtype (Eq, Bounded, Enum)

newtype Background = Background InputState
    deriving newtype (Eq, Bounded, Enum)

instance Token Background where
    tokenName (Background state) = "input-background-" <> tokenName state
    tokenAttr (Background state) = tokenAttr state

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue (Background state) =
        tokenValue (Colour.Text Default) <&> \(ColorOKLCHA l c h _) ->
            ColorOKLCHA l c h $ case state of
                HoveredState -> 0.05
                _ -> 0

data Type
    = Text
    | Password
    | Number
    | Email
    | MultiLine
    deriving stock (Eq, Bounded, Enum)

instance Token Type where
    tokenName Text = "text"
    tokenName Password = "password"
    tokenName Number = "number"
    tokenName Email = "email"
    tokenName MultiLine = "multiline"
    tokenAttr = type_ . tokenName
    byToken = ("type" @=) . tokenName

data TextField action = TextField
    { name :: MisoString
    , type' :: Type
    , value :: Maybe MisoString
    , isValid :: Bool
    , onChange :: MisoString -> action
    }

instance Widget (TextField action) model action where
    widget' attrs TextField{..}
        | type' == MultiLine = textarea_ attrs' . fmap text . maybeToList $ value
        | otherwise = input_ (tokenAttr type' : attrs' <> (value_ <$> maybeToList value))
      where
        attrs' = name_ name : Miso.onInput onChange : attrs
    style = do
        ":root" ? tokenDecl @Background
        (select <> textarea <> input # isOneOfAll' @Type) ? do
            display block
            fullWidth
            focusable
            border (var "border-width" []) solid (colorToken Colour.Border)
            byToken Subtle & borderColor transparent
            paddingAll' XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.2) easeOut 0
            backgroundColor' $ Background DefaultState
            hover <> Clay.not focusVisible & do
                borderColor' Colour.Border
                backgroundColor' $ Background HoveredState
            focusVisible & do
                borderColor' Colour.BorderFocused
                backgroundColor' $ Background ActiveState
            ":user-invalid" & ":not(:focus-visible)" & borderColor' Colour.BorderDanger
        textarea ? do
            "resize" -: "vertical"
            minHeight $ em 10
