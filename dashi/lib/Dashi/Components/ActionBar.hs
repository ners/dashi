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
import Clay qualified
import Dashi.Prelude hiding (Left, Right, has, (#), (&), (**))
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
            . mconcat
            $ [ [div_ [tokenAttr Left] left | not $ null left]
              , [div_ [tokenAttr Centre] centre | not $ null centre]
              , [div_ [tokenAttr Right] right | not $ null right]
              ]
    style = do
        form ? ".action-bar" ? marginTop (token $ Space Medium)
        ".action-bar" ? do
            fullWidth
            sconcat (has . ("" #) . byToken <$> allTokens @Area) & do
                display grid
                byTokens \area -> do
                    "grid-area" -: tokenName area
                    display flex
                    flexDirection row
                    gap' XSmall
                    justifyContent $ case area of
                        Left -> flexStart
                        Centre -> center
                        Right -> flexEnd
                gridTemplateAreas [tokenName <$> allTokens @Area]
                gridTemplateColumns [fr 1, fr 1, fr 1]
            Clay.not (has ("" # byToken Centre)) & do
                display flex
                flexDirection row
                alignItems baseline
                justifyContent spaceBetween
                "" ? byTokens \case
                    Left -> pure ()
                    Centre -> pure ()
                    Right -> textAlign end
