{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Breadcrumbs where

import Clay hiding (Color, action, href, label)
import Dashi.Components.Icon (MDI (MdiChevronRight))
import Dashi.Prelude hiding ((#), (&), (|>))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util (color', token)
import Data.List qualified as List
import Miso.Html.Element (div_)
import Miso.Html.Property (class_)

newtype Breadcrumbs model action = Breadcrumbs {crumbs :: [View model action]}

instance Widget (Breadcrumbs model action) model action where
    widget' attrs Breadcrumbs{..} = div_ (class_ "breadcrumbs" : attrs) $ List.intersperse separator crumbs
      where
        separator :: View model action
        separator = widget' [class_ "separator"] MdiChevronRight
    style =
        ".breadcrumbs" ? do
            display flex
            flexDirection row
            ".separator" ? do
                color' (Colour.Text Subtle)
                width . token $ Space Medium
