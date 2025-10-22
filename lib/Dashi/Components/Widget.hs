module Dashi.Components.Widget where

import Miso

class Widget w where
    widget' :: [Attribute action] -> w -> View model action
    widget :: w -> View model action
    widget = widget' []
