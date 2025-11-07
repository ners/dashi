{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (Background, Color, Number, fullWidth, label, name, span_, type_, value, var)
import Dashi.Components.Widget
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Graphics.Color.Space (Alpha)
import Graphics.Color.Space.OKLAB.LCH
import Miso (MisoString)
import Miso.Html.Element (input_)
import Miso.Html.Property (name_, type_)
import Prelude

newtype Border = Border InputState
    deriving newtype (Eq, Bounded, Enum)

newtype Background = Background InputState
    deriving newtype (Eq, Bounded, Enum)

instance Token Background where
    tokenName (Background state) = "input-background-" <> tokenName state
    tokenAttr (Background state) = tokenAttr state

instance ValueToken Background where
    type ValueType Background = Color (Alpha OKLCH) Float
    tokenValue (Background state) =
        ColorOKLCHA l c h $ case state of
            HoveredState -> 0.05
            _ -> 0
      where
        ColorOKLCHA l c h _ = tokenValue $ Colour.Text Default

data Type
    = Text
    | Password
    | Number
    | Email
    deriving stock (Eq, Ord, Bounded, Enum)

instance Token Type where
    tokenName Text = "text"
    tokenName Password = "password"
    tokenName Number = "number"
    tokenName Email = "email"
    tokenAttr = type_ . tokenName
    byToken = ("type" @=) . tokenName

data TextField = TextField
    { name :: MisoString
    , type' :: Type
    , value :: Maybe MisoString
    , isValid :: Bool
    }

instance Widget TextField model action where
    widget' attrs TextField{..} = input_ (tokenAttr type' : name_ name : attrs)
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
                borderColor' $ Colour.Border
                backgroundColor' $ Background HoveredState
            focusVisible & do
                borderColor' Colour.BorderFocused
                backgroundColor' $ Background ActiveState
            ":user-invalid" & ":not(:focus-visible)" & borderColor' Colour.BorderDanger
