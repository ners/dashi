{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Breadcrumbs where

import Clay hiding (Color, action, href, label, span_)
import Dashi.Components.Icon (MDI (MdiChevronRight), iconContent, iconStyle)
import Dashi.Prelude hiding (has, (#), (&), (|>))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util (color', has, token)
import Data.List qualified as List
import Miso.Html.Element (div_, span_)
import Miso.Html.Property (class_)

newtype Breadcrumbs model action = Breadcrumbs {crumbs :: [View model action]}

instance Widget (Breadcrumbs model action) model action where
    widget' attrs Breadcrumbs{..} = div_ (class_ "breadcrumbs" : attrs) $ List.intersperse separator crumbs
      where
        separator :: View model action
        separator = span_ [class_ "separator"] []
    style =
        ".breadcrumbs" ? do
            display flex
            flexDirection row
            ".separator" ? do
                color' (Colour.Text Subtle)
                width . token $ Space Medium
                iconStyle
                before & content (iconContent MdiChevronRight)
            has ".mdi" & ".separator" ? do
                position relative
                top $ em 0.1
