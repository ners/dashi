{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Heading where

import Clay hiding (element, size)
import Dashi.Components.Icon ()
import Dashi.Prelude hiding (element)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (h1_, h2_, h3_, h4_, h5_)

selector :: SizeToken -> Selector
selector XSmall = h5
selector Small = h4
selector Medium = h3
selector Large = h2
selector XLarge = h1

element
    :: SizeToken
    -> [Attribute action]
    -> [View model action]
    -> View model action
element XSmall = h5_
element Small = h4_
element Medium = h3_
element Large = h2_
element XLarge = h1_

data Heading = Heading SizeToken MisoString

instance Widget Heading model action where
    widget' attrs (Heading size t) = element size attrs [text t]
    style = do
        sconcat (selector <$> allTokens) ? fontWeight (weight 600)
        for_ @[] allTokens \size ->
            selector size ? fontSize' size
