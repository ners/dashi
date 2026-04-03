{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Heading where

import Clay hiding (FontSize, element, fontSize, size)
import Clay qualified
import Dashi.Components.Icon ()
import Dashi.Prelude hiding (element)
import Dashi.Style.Tokens hiding (FontSize)
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

newtype FontSize = FontSize SizeToken
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token FontSize where
    tokenName (FontSize fontSize) = fromString $ "heading-" <> tokenName fontSize <> "-font-size"

instance ValueToken FontSize where
    type ValueType FontSize = Size Percentage
    tokenValue (FontSize fontSize) = pct $ case fontSize of
        XSmall -> 85
        Small -> 100
        Medium -> 125
        Large -> 150
        XLarge -> 200

data Heading = Heading SizeToken MisoString

instance Widget Heading model action where
    widget' attrs (Heading size t) = element size attrs [text t]
    style = do
        sconcat (selector <$> allTokens) ? fontWeight (weight 600)
        for_ @[] allTokens \size ->
            selector size ? Clay.fontSize (tokenValue $ FontSize size)
