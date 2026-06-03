{-# LANGUAGE AllowAmbiguousTypes #-}

module Dashi.Components.Widget where

import Clay (Css)
import Miso.Prelude

class Widget w model action where
    widget' :: [Attribute action] -> w -> View model action
    widget :: w -> View model action
    widget = widget' []
    style :: Css

data SomeWidget = forall w model action. (Widget w model action) => SomeWidget w

instance Widget () model action where
    widget' _ () = VFrag Nothing []
    style = pure ()

instance Widget (View model action) model action where
    widget' :: [Attribute action] -> View model action -> View model action
    widget' _ view = view
    style = pure ()
