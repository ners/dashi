{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style where

import Clay hiding (style)
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.TextField qualified as TextField
import Dashi.Layout.Page qualified as Page
import Dashi.Style.Root qualified as Root
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Prelude
import Dashi.Components.Banner qualified as Banner
import Dashi.Components.InlineMessage qualified as InlineMessage

style :: Css
style = do
    Root.style
    Banner.style
    Button.style
    Icon.style
    InlineMessage.style
    Page.style
    TextField.style

styleStr :: (IsString s) => s
styleStr = fromString . LazyText.unpack . renderWith pretty [] $ style
