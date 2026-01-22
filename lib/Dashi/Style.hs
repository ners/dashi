{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style where

import Clay hiding (style)
import Dashi.Components.ActionBar (ActionBar)
import Dashi.Components.Avatar (Avatar, AvatarItem)
import Dashi.Components.Button (Button)
import Dashi.Components.Checkbox (Checkbox, CheckboxGroup)
import Dashi.Components.Form (FormField)
import Dashi.Components.Heading (Heading)
import Dashi.Components.Link (Link)
import Dashi.Components.Message (Message)
import Dashi.Components.Plot (Plot)
import Dashi.Components.ProgressBar (ProgressBar)
import Dashi.Components.Radio (Radio, RadioGroup)
import Dashi.Components.Range (Range)
import Dashi.Components.Select (Select)
import Dashi.Components.Switch (Switch)
import Dashi.Components.Tabs (Tabs)
import Dashi.Components.TextField (TextField)
import Dashi.Components.Widget qualified as Widget
import Dashi.Layout.Page (Page)
import Dashi.Style.Root qualified as Root
import Web.Font.MDI (MDI)
import Prelude

style :: forall value model action. (value ~ (), model ~ (), action ~ ()) => Css
style = do
    Root.style

    Widget.style @(Page model action) @model @action

    Widget.style @(ActionBar model action) @model @action
    Widget.style @(Button model action) @model @action
    Widget.style @(Checkbox model action) @model @action
    Widget.style @(CheckboxGroup value model action) @model @action
    Widget.style @(FormField value model action) @model @action
    Widget.style @(Link model action) @model @action
    Widget.style @(Radio model action) @model @action
    Widget.style @(RadioGroup value model action) @model @action
    Widget.style @(Range action) @model @action
    Widget.style @(Select value model action) @model @action
    Widget.style @(Switch model action) @model @action
    Widget.style @(Tabs value model action) @model @action
    Widget.style @(TextField action) @model @action
    Widget.style @Avatar @model @action
    Widget.style @AvatarItem @model @action
    Widget.style @Heading
    Widget.style @MDI
    Widget.style @Message
    Widget.style @(Plot Double) @model @action
    Widget.style @ProgressBar @model @action
