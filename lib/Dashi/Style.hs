{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style where

import Clay hiding (style)
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Message qualified as Message
import Dashi.Components.TextField qualified as TextField
import Dashi.Layout.Page qualified as Page
import Dashi.Style.Root qualified as Root
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Prelude

style :: Css
style = do
    Root.style
    Button.style
    Icon.style
    Message.style
    Page.style
    TextField.style

styleStr :: (IsString s) => s
styleStr = fromString . LazyText.unpack . renderWith pretty [] $ style
