{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Link where

import Clay hiding (Color, action, href, label)
import Dashi.Components.Widget
import Dashi.Style.Colour (LightDark)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util (color', pressable)
import Graphics.Color.Space (Alpha)
import Graphics.Color.Space.OKLAB.LCH
import Miso
import Miso.Html.Element (a_)
import Miso.Html.Property (href_)
import Prelude

data Text = Text
    deriving stock (Eq, Bounded, Enum)

instance Token Text where
    tokenName Text = "text-link"

instance ValueToken Text where
    type ValueType Text = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Text = tokenValue $ Colour.Text Primary

data Link model action = Link
    { href :: MisoString
    , label :: [View model action]
    }

instance Widget (Link model action) model action where
    widget' attrs Link{..} = a_ (href_ href : attrs) label
    style = do
        ":root" ? tokenDecl @Text
        a ? do
            pressable
            "@href" & do
                color' Text
                hover & textDecoration underline
                byToken Subtle & color' (Colour.Text Subtle)
