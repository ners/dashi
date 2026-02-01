{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.ActionBar where

import Clay hiding
    ( area
    , fullWidth
    , left
    , legend
    , name
    , not
    , option
    , required
    , right
    , selected
    , span_
    , type_
    )
import Dashi.Prelude hiding (Left, Right, (#), (**))
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (div_)
import Miso.Html.Property (class_)

data Area
    = Left
    | Centre
    | Right
    deriving stock (Eq, Ord, Bounded, Enum)

instance Token Area where
    tokenName Left = "left"
    tokenName Centre = "centre"
    tokenName Right = "right"

data ActionBar model action = ActionBar
    { left :: [View model action]
    , centre :: [View model action]
    , right :: [View model action]
    }

instance Widget (ActionBar model action) model action where
    widget' attrs ActionBar{..} =
        div_
            (class_ "action-bar" : attrs)
            [ div_ [class_ "left"] left
            , div_ [class_ "centre"] centre
            , div_ [class_ "right"] right
            ]
    style =
        ".action-bar" ? do
            fullWidth
            display grid
            gridTemplateAreas [tokenName <$> allTokens @Area]
            gridTemplateColumns [fr 1, fr 1, fr 1]
            for_ @[] allTokens \area ->
                self # byToken area ? do
                    "grid-area" -: tokenName area
                    display flex
                    flexDirection row
                    gap' XSmall
                    justifyContent $ case area of
                        Left -> flexStart
                        Centre -> center
                        Right -> flexEnd
