{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (Background, icon, size, span_, title)
import Dashi.Components.Icon (iconContent)
import Dashi.Components.Util (selectable_)
import Dashi.Prelude hiding (has, none, (#), (&))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (a_, div_, span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI (MdiAlert, MdiAlertRhombus, MdiCheckCircle, MdiHelpCircle, MdiInformation))

data MessageSize
    = InlineMessage
    | FormMessage
    | SectionMessage
    deriving stock (Eq, Bounded, Enum)

instance Token MessageSize where
    tokenName InlineMessage = "inline"
    tokenName FormMessage = "form"
    tokenName SectionMessage = "section"

data Message = Message
    { size :: MessageSize
    , appearance :: Appearance
    , title :: Maybe MisoString
    , secondary :: Maybe MisoString
    }

instance Widget Message model action where
    widget' attrs Message{..} =
        tag (class_ "message" : tokenAttr size : tokenAttr appearance : attrs)
            . catMaybes
            $ [ pure $ span_ [class_ "mdi"] []
              , span_ [class_ "title"] . pure . text <$> title
              , span_ [class_ "secondary"] . pure . text <$> secondary
              ]
      where
        tag
            | size == InlineMessage = a_ . (selectable_ :)
            | otherwise = div_

    style =
        ".message" ? do
            maxWidth $ pct 100
            byToken InlineMessage & do
                pressable
                underlinedOnHover
                display inlineFlex
                flexDirection row
                alignItems center
                ".title" ? color' (Colour.Text Default)
                ".secondary" ? color' (Colour.Text Subtle)
                fontWeight $ weight 500
                gap' XSmall
            byToken FormMessage & do
                display flex
                flexDirection row
                alignItems center
                gap' XSmall
            byToken SectionMessage & do
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
            byToken FormMessage & do
                fontSize' Small
                byToken Subtle & ".mdi" ? display none
            let icon Default = MdiInformation
                icon Primary = icon Default
                icon Subtle = icon Default
                icon Success = MdiCheckCircle
                icon Warning = MdiAlert
                icon Danger = MdiAlertRhombus
                icon Discovery = MdiHelpCircle
            for_ @[] [minBound .. maxBound] \appearance ->
                byToken appearance & do
                    byToken FormMessage & color' (Colour.Text appearance)
                    byToken SectionMessage & backgroundColor' (Colour.Background appearance)
                    ".mdi" # before ? do
                        content . iconContent . icon $ appearance
                        color' $ Colour.Text appearance
