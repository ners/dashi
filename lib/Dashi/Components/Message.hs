{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (Background, icon, size, span_, title)
import Control.Monad (forM_)
import Dashi.Components.Util (selectable_)
import Dashi.Components.Widget
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Maybe (catMaybes)
import Data.Text qualified as Text
import Miso
import Miso.Html.Element (a_, div_, span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI (MdiAlert, MdiAlertRhombus, MdiCheckCircle, MdiHelpCircle, MdiInformation), mdiChar)
import Prelude

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

instance Widget Message where
    widget' attrs Message{..} =
        tag (class_ "message" : tokenAttr size : tokenAttr appearance : attrs) . catMaybes $
            [ pure $ span_ [class_ "mdi"] []
            , span_ [class_ "title"] . pure . text <$> title
            , span_ [class_ "secondary"] . pure . text <$> secondary
            ]
      where
        tag
            | size == InlineMessage = a_ . (selectable_ :)
            | otherwise = div_

style :: Css
style =
    ".message" ? do
        maxWidth $ pct 100
        byToken InlineMessage & do
            pressable
            underlinedOnHover
            display inlineFlex
            flexDirection row
            alignItems center
            ".title" ? color' (Text Default)
            ".secondary" ? color' (Text Subtle)
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
            display grid
            gridTemplateAreas
                [ ["icon", "title"]
                , ["icon", "secondary"]
                ]
            gridTemplateColumns [em 1.5, auto]
            columnGap' Small
            ".mdi" ? ("grid-area" -: "icon")
            ".title" ? do
                "grid-area" -: "title"
                fontSize $ pct 115
                fontWeight $ weight 700
            ".secondary" ? ("grid-area" -: "secondary")
            -- There is no title, so put the secondary text in the title row
            ".mdi" |+ ".secondary" ? ("grid-area" -: "title")
            ".title" |+ ".secondary" ? (marginTop . token $ Space XSmall)
        byToken FormMessage & do
            fontSize (pct 80)
            byToken Subtle & ".mdi" ? display none
            marginTop . token $ Space XSmall
        let icon Default = MdiInformation
            icon Primary = icon Default
            icon Subtle = icon Default
            icon Success = MdiCheckCircle
            icon Warning = MdiAlert
            icon Danger = MdiAlertRhombus
            icon Discovery = MdiHelpCircle
        forM_ [minBound .. maxBound] \appearance ->
            byToken appearance & do
                byToken FormMessage & color' (Text appearance)
                byToken SectionMessage & backgroundColor' (Background appearance)
                ".mdi" # before ? do
                    content . stringContent . Text.singleton . mdiChar . icon $ appearance
                    color' $ Icon appearance
