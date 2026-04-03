{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (Background, i, icon, size, span_, title)
import Dashi.Components.Icon
    ( Icon (..)
    , Phosphor (CheckCircle, Info, Question, WarningDiamond)
    , Weight (..)
    )
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Util (selectable_)
import Dashi.Prelude hiding (has, none, (#), (&))
import Dashi.Style.Background (BackgroundColour (BackgroundColour))
import Dashi.Style.Pseudo (pressable)
import Dashi.Style.Text (TextColour (TextColour))
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (a_, div_, span_)
import Miso.Html.Property (class_)

data MessageSize
    = InlineMessage
    | FormMessage
    | SectionMessage
    deriving stock (Eq, Bounded, Enum)

instance Token MessageSize where
    tokenName InlineMessage = "inline"
    tokenName FormMessage = "form"
    tokenName SectionMessage = "section"

data MessageIcon
    = DefaultIcon
    | CustomIcon Icon

data Message = Message
    { size :: MessageSize
    , appearance :: Appearance
    , icon :: Maybe MessageIcon
    , title :: Maybe MisoString
    , secondary :: Maybe MisoString
    }

sizeStyle :: MessageSize -> Css
sizeStyle InlineMessage = do
    pressable
    underlinedOnHover
    display inlineFlex
    flexDirection row
    alignItems center
    ".title" ? color' (TextColour Default)
    ".secondary" ? color' (TextColour Subtle)
    fontWeight $ weight 500
    gap' XSmall
    ".icon" ? do
        position relative
        top . em $ -0.025
sizeStyle FormMessage = do
    display flex
    flexDirection row
    alignItems center
    gap' XSmall
    ".icon" ? do
        fontSize' Large
        position relative
        top . em $ -0.01
    fontSize' Small
sizeStyle SectionMessage = do
    borderRadiusAll' Medium
    paddingAll' Medium
    paddingRight . tokenValue . Space $ Large
    display flex
    alignItems center
    sconcat [has ".title", has ".secondary"] & do
        display grid
        gridTemplateAreas
            [ ["icon", "title"]
            , ["icon", "secondary"]
            ]
        ".icon" ? ("grid-area" -: "icon")
        ".title" ? ("grid-area" -: "title")
        ".secondary" ? ("grid-area" -: "secondary")
        rowGap' XSmall
    gridTemplateColumns [em 1.5, auto]
    columnGap' Small
    ".title" ? do
        fontSize' Large
        fontWeight $ weight 700
    ".icon" ? do
        fontSize (pct 150)
        alignSelf baseline
    Clay.not (has ".title") & ".icon" ? do
        position relative
        top . em $ -0.05

defaultIcon :: Appearance -> Maybe Icon
defaultIcon Default = Nothing
defaultIcon Primary = Just $ Icon Fill Info
defaultIcon Subtle = Nothing
defaultIcon Success = Just $ Icon Fill CheckCircle
defaultIcon Warning = Just $ Icon Fill Icon.Warning
defaultIcon Danger = Just $ Icon Fill WarningDiamond
defaultIcon Discovery = Just $ Icon Fill Question

appearanceStyle :: Appearance -> Css
appearanceStyle appearance = do
    byToken FormMessage & color' (TextColour appearance)
    byToken SectionMessage & backgroundColor' (BackgroundColour appearance)
    ".icon" ? color' (TextColour appearance)

instance Widget Message model action where
    widget' attrs Message{..} =
        tag (class_ "message" : tokenAttr size : tokenAttr appearance : attrs)
            . catMaybes
            $ [ widget <$> icon'
              , span_ [class_ "title"] . pure . text <$> title
              , span_ [class_ "secondary"] . pure . text <$> secondary
              ]
      where
        icon' =
            icon >>= \case
                DefaultIcon -> defaultIcon appearance
                CustomIcon i -> Just i
        tag
            | size == InlineMessage = a_ . (selectable_ :)
            | otherwise = div_

    style =
        ".message" ? do
            maxWidth $ pct 100
            byTokens sizeStyle
            byTokens appearanceStyle
