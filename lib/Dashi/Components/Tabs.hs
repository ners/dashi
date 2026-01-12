{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Tabs where

import Clay hiding (label, name, selected, span_, type_)
import Dashi.Components.Util (ariaRole_)
import Dashi.Prelude hiding (none, (&))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (li_, ul_)
import Miso.Html.Event (onClick)
import Miso.Html.Property (aria_, class_, tabindex_)

data Tabs t model action = Tabs
    { tabs :: [t]
    , label :: t -> [View model action]
    , selected :: t -> Bool
    , onSelect :: t -> action
    }

instance Widget (Tabs t model action) model action where
    widget' attrs Tabs{..} =
        ul_
            (class_ "tabs" : ariaRole_ "group" : attrs)
            [ li_ (tabindex_ "0" : onClick (onSelect tab) : [aria_ "current" "true" | selected tab]) . label $ tab
            | tab <- tabs
            ]
    style =
        ".tabs" ? do
            display flex
            flexDirection row
            listStyleType none
            borderBottom (em 0.1) solid (colorToken Colour.Border)
            li ? do
                pressable
                paddingYX' XSmall Small
                fontWeight $ weight 500
                position relative
                color' $ Colour.Text Subtle
                after & do
                    content $ stringContent ""
                    display block
                    position absolute
                    left nil
                    right nil
                    bottom . em $ -0.2
                    borderBottom (em 0.3) solid transparent
                "@aria-current" & do
                    color' $ Colour.Text Primary
                    after & borderBottomColor (colorToken Colour.BorderFocused)
                hover <> Clay.not @Refinement "@aria-current" & do
                    borderBottomColor $ colorToken Colour.Border
                    after & borderBottomColor (colorToken Colour.Border)
                pure ()
