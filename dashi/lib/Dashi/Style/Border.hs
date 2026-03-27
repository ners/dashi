module Dashi.Style.Border where

import Dashi.Prelude
import Dashi.Style.Colour
import Dashi.Style.Tokens (Token (..), ValueToken (..))
import Dashi.Style.Uchu (Uchu (..))

data BorderColour
    = BorderColour
    | BorderFocusedColour
    | BorderDangerColour
    deriving stock (Eq, Bounded, Enum)

instance Token BorderColour where
    tokenName BorderColour = "border-color"
    tokenName BorderFocusedColour = "border-focused-color"
    tokenName BorderDangerColour = "border-danger-color"

instance ValueToken BorderColour where
    type ValueType BorderColour = LightDark Uchu
    tokenValue BorderColour = LightDark Yin3 Yin8
    tokenValue BorderFocusedColour = sameLightDark Blue
    tokenValue BorderDangerColour = sameLightDark Red
