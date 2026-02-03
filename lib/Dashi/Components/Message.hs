{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (Background, i, icon, size, span_, title)
import Dashi.Components.Icon
    ( MDI
        ( MdiAlert
        , MdiAlertRhombus
        , MdiCheckCircle
        , MdiHelpCircle
        , MdiInformation
        )
    )
import Dashi.Components.Icon qualified as Components
import Dashi.Components.Util (selectable_)
import Dashi.Prelude hiding (has, none, (#), (&))
import Dashi.Style.Colour qualified as Colour
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

data Icon
    = DefaultIcon
    | CustomIcon Components.Icon

data Message = Message
    { size :: MessageSize
    , appearance :: Appearance
    , icon :: Maybe Icon
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
    ".title" ? color' (Colour.Text Default)
    ".secondary" ? color' (Colour.Text Subtle)
    fontWeight $ weight 500
    gap' XSmall
sizeStyle FormMessage = do
    display flex
    flexDirection row
    alignItems center
    gap' XSmall
    ".mdi" ? do
        fontSize' Large
        position relative
        top . em $ -0.05
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
        ".mdi" ? do
            "grid-area" -: "icon"
            alignSelf baseline
        ".title" ? ("grid-area" -: "title")
        ".secondary" ? ("grid-area" -: "secondary")
        rowGap' XSmall
    gridTemplateColumns [em 1.5, auto]
    columnGap' Small
    ".title" ? do
        fontSize' Large
        fontWeight $ weight 700

defaultIcon :: Appearance -> Maybe Components.Icon
defaultIcon Default = Nothing
defaultIcon Primary = Just MdiInformation
defaultIcon Subtle = Nothing
defaultIcon Success = Just MdiCheckCircle
defaultIcon Warning = Just MdiAlert
defaultIcon Danger = Just MdiAlertRhombus
defaultIcon Discovery = Just MdiHelpCircle

appearanceStyle :: Appearance -> Css
appearanceStyle appearance = do
    byToken FormMessage & color' (Colour.Text appearance)
    byToken SectionMessage & backgroundColor' (Colour.Background appearance)
    ".mdi" ? color' (Colour.Text appearance)

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
