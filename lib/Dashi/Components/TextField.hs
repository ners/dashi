{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding (Background, Number, fullWidth, label, name, span_, type_, value, var)
import Dashi.Components.Widget
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens hiding (Background, Text)
import Dashi.Style.Util
import Miso (MisoString)
import Miso.Html.Element (input_)
import Miso.Html.Property (name_, type_)
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
            border (var "border-width" []) solid (token InputBorder)
            byToken Subtle & do
                "border" ~: none
                hover & border (var "border-width" []) solid (token InputBorder)
            paddingAll' XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.1) easeOut 0
            backgroundColor' $ Background DefaultState
            hover & backgroundColor' (Background HoveredState)
            active & backgroundColor' (Background PressedState)
            ":user-invalid" & ":not(:focus-visible)" & borderColor' InputBorderDanger
