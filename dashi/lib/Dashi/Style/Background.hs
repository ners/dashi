module Dashi.Style.Background where

import Dashi.Prelude
import Dashi.Style.Colour
import Dashi.Style.Tokens (Appearance (..), Token (..), ValueToken (..))
import Dashi.Style.Uchu

newtype BackgroundColour = BackgroundColour Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token BackgroundColour where
    tokenName (BackgroundColour appearance) = "background-" <> tokenName appearance

instance ValueToken BackgroundColour where
    type ValueType BackgroundColour = LightDark (UchuAlpha Milli)
    tokenValue (BackgroundColour Default) = flip UchuAlpha 1 <$> LightDark Yang Yin
    tokenValue (BackgroundColour Subtle) = flip UchuAlpha 0 <$> LightDark Yang Yin
    tokenValue (BackgroundColour Primary) = flip UchuAlpha 0.15 <$> sameLightDark Blue
    tokenValue (BackgroundColour Success) = flip UchuAlpha 0.15 <$> sameLightDark Green
    tokenValue (BackgroundColour Warning) = flip UchuAlpha 0.15 <$> sameLightDark Orange
    tokenValue (BackgroundColour Danger) = flip UchuAlpha 0.15 <$> sameLightDark Red
    tokenValue (BackgroundColour Discovery) = flip UchuAlpha 0.15 <$> sameLightDark Purple
