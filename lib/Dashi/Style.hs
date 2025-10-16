module Dashi.Style where

import Clay
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon qualified as Icon
import Dashi.Style.Root qualified as Root
import Prelude

style :: Css
style = do
    Root.style
    Button.style
    Icon.style
