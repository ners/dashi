{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style where

import Clay hiding (style)
import Dashi.Components.ActionBar (ActionBar)
import Dashi.Components.Avatar (Avatar, AvatarItem)
import Dashi.Components.Button (Button)
import Dashi.Components.Checkbox (Checkbox, CheckboxGroup)
import Dashi.Components.Form (FormField)
import Dashi.Components.Heading (Heading)
import Dashi.Components.Message (Message)
import Dashi.Components.Radio (Radio, RadioGroup)
import Dashi.Components.Select (Select)
import Dashi.Components.TextArea (TextArea)
import Dashi.Components.TextField (TextField)
import Dashi.Components.Widget qualified as Widget
import Dashi.Layout.Page qualified as Page
import Dashi.Style.Root qualified as Root
import Data.String (IsString (fromString))
import Data.Text.Lazy qualified as LazyText
import Web.Font.MDI (MDI)
import Prelude

style :: forall value model action. (value ~ (), model ~ (), action ~ ()) => Css
style = do
    Root.style
    Page.style

    Widget.style @Avatar @model @action
    Widget.style @AvatarItem @model @action
    Widget.style @(ActionBar model action) @model @action
    Widget.style @(Button model action) @model @action
    Widget.style @(Checkbox model action) @model @action
    Widget.style @(CheckboxGroup value model action) @model @action
    Widget.style @(FormField value model action) @model @action
    Widget.style @(Radio model action) @model @action
    Widget.style @(RadioGroup value model action) @model @action
    Widget.style @(Select value model action) @model @action
    Widget.style @Heading
    Widget.style @MDI
    Widget.style @Message
    Widget.style @TextArea
    Widget.style @TextField

styleStr :: (IsString s) => s
styleStr = fromString . LazyText.unpack . renderWith pretty [] $ style
