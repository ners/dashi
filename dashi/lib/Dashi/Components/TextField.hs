{-# OPTIONS_GHC -Wno-missing-poly-kind-signatures #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.TextField where

import Clay hiding
    ( Background
    , Color
    , Number
    , fullWidth
    , name
    , not
    , type_
    , valid
    , value
    , var
    )
import Clay qualified
import Dashi.Components.Util (ariaInvalid_)
import Dashi.Prelude hiding ((#), (&))
import Dashi.Style.Border (BorderColour (..))
import Dashi.Style.Colour (LightDark (..))
import Dashi.Style.Pseudo (focusable)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu (..), UchuAlpha (..))
import Dashi.Style.Util
import Miso.Html.Element (input_, textarea_)
import Miso.Html.Event qualified as Html
import Miso.Html.Property (name_, type_, value_)

newtype Border = Border InputState
    deriving newtype (Eq, Bounded, Enum)

newtype Background = Background InputState
    deriving newtype (Eq, Bounded, Enum)

instance Token Background where
    tokenName (Background state) = "input-background-" <> tokenName state
    tokenAttr (Background state) = tokenAttr state

instance ValueToken Background where
    type ValueType Background = LightDark (UchuAlpha Milli)
    tokenValue (Background state) = flip UchuAlpha alpha <$> LightDark Yin Yang
      where
        alpha
            | state == HoveredState = 0.05
            | otherwise = 0

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
    , valid :: Bool
    , onChange :: MisoString -> action
    }

instance Widget (TextField action) model action where
    widget' attrs TextField{..}
        | type' == MultiLine = textarea_ attrs' $ fromMaybe "" value
        | otherwise =
            input_ (tokenAttr type' : attrs' <> (value_ <$> maybeToList value))
      where
        attrs' = name_ name : Html.onInput onChange : attrs <> [ariaInvalid_ True | not valid]
    style = do
        ":root" ? tokenDecl @Background
        (Clay.select <> textarea <> input # isOneOfAll' @Type) ? do
            display block
            fullWidth
            focusable
            border (token BorderWidth) solid (colorToken BorderColour)
            byToken Subtle & do
                borderColor transparent
            paddingAll' XSmall
            borderRadiusAll' Small
            transition "background" (sec 0.2) easeOut 0
            backgroundColor' $ Background DefaultState
            hover <> Clay.not focusVisible & do
                borderColor' BorderColour
                backgroundColor' $ Background HoveredState
            focusVisible & do
                borderColor' BorderFocusedColour
                backgroundColor' $ Background ActiveState
            isOneOf [":user-invalid", "aria-invalid" @= "true"]
                & ":not(:focus-visible)"
                & borderColor' BorderDangerColour
        textarea ? do
            "resize" -: "vertical"
            minHeight $ em 10
