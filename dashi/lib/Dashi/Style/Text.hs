module Dashi.Style.Text where

import Dashi.Prelude
import Dashi.Style.Colour
import Dashi.Style.Tokens (Appearance (..), Token (..), ValueToken (..))
import Dashi.Style.Uchu
import Dashi.Style.Uchu qualified as Uchu

newtype TextColour = TextColour Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token TextColour where
    tokenName (TextColour appearance) = "text-" <> tokenName appearance <> "-color"

instance ValueToken TextColour where
    type ValueType TextColour = LightDark (UchuAlpha Micro)
    tokenValue (TextColour Default) = flip UchuAlpha 1 <$> LightDark Yin Yang
    tokenValue (TextColour Subtle) = Uchu.setAlpha 0.75 <$> tokenValue (TextColour Default)
    tokenValue (TextColour Primary) = flip UchuAlpha 1 <$> sameLightDark Blue
    tokenValue (TextColour Success) = flip UchuAlpha 1 <$> sameLightDark Green6
    tokenValue (TextColour Warning) = flip UchuAlpha 1 <$> sameLightDark Orange6
    tokenValue (TextColour Danger) = flip UchuAlpha 1 <$> sameLightDark Red
    tokenValue (TextColour Discovery) = flip UchuAlpha 1 <$> sameLightDark Purple

data InverseTextColour = InverseTextColour
    deriving stock (Eq, Bounded, Enum)

instance Token InverseTextColour where
    tokenName InverseTextColour = "text-inverse-color"

instance ValueToken InverseTextColour where
    type ValueType InverseTextColour = LightDark (UchuAlpha Micro)
    tokenValue InverseTextColour = flipLightDark . tokenValue $ TextColour Default
