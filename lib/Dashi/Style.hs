{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style where

import Clay hiding (style)
import Dashi.Components.Button (Button)
import Dashi.Components.Checkbox (Checkbox)
import Dashi.Components.Message (Message)
import Dashi.Components.Radio (Radio)
import Dashi.Components.TextField (TextField)
import Dashi.Components.Widget qualified as Widget
import Dashi.Layout.Page qualified as Page
import Dashi.Style.Root qualified as Root
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Data.Void (Void)
import Web.Font.MDI (MDI)
import Prelude

style :: Css
style = do
    Root.style
    Page.style

    Widget.style @Button
    Widget.style @(Checkbox Void)
    Widget.style @MDI
    Widget.style @Message
    Widget.style @(Radio Void)
    Widget.style @TextField

styleStr :: (IsString s) => s
styleStr = fromString . LazyText.unpack . renderWith pretty [] $ style
