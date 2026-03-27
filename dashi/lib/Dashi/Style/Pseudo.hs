module Dashi.Style.Pseudo where

import Clay hiding (var)
import Dashi.Style.Border (BorderColour (BorderFocusedColour))
import Dashi.Style.Util

focusable :: Css
focusable =
    focusVisible
        & outline solid (var "outline-width" []) (colorToken BorderFocusedColour)

pressable :: Css
pressable = do
    cursor pointer
    focusable
