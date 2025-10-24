{-# LANGUAGE AllowAmbiguousTypes #-}

module Dashi.Components.Widget where

import Clay (Css)
import Miso

class Widget w where
    widget' :: [Attribute action] -> w -> View model action
    widget :: w -> View model action
    widget = widget' []
    style :: Css
