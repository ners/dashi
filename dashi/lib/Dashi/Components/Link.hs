{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Link where

import Clay hiding (Color, action, href, label)
import Dashi.Prelude hiding ((&))
import Dashi.Style.Colour (LightDark (..))
import Dashi.Style.Pseudo (pressable)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Text (TextColour (TextColour))
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu (..))
import Dashi.Style.Util (color')
import Miso.Html.Element (a_)
import Miso.Html.Property (href_)

data Text = Text
    deriving stock (Eq, Bounded, Enum)

instance Token Text where
    tokenName Text = "text-link"

instance ValueToken Text where
    type ValueType Text = LightDark Uchu
    tokenValue Text = LightDark Blue5 Blue3

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
                byToken Subtle & color' (TextColour Subtle)
