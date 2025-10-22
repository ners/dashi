{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (span_, title)
import Control.Monad (forM_)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Maybe (catMaybes)
import Data.Text qualified as Text
import Miso
import Miso.Html.Element (a_, span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI (MdiAlert, MdiAlertRhombus, MdiCheckCircle, MdiHelpCircle, MdiInformation), mdiChar)
import Prelude

data MessageSize
    = InlineMessage
    | FormMessage
    | SectionMessage
    deriving stock (Eq, Bounded, Enum, Show)

instance Token MessageSize where
    tokenName InlineMessage = "inline"
    tokenName FormMessage = "form"
    tokenName SectionMessage = "section"

data MessageAppearance
    = InfoMessage
    | WarningMessage
    | ErrorMessage
    | SuccessMessage
    | DiscoveryMessage
    deriving stock (Eq, Bounded, Enum, Show)

instance Token MessageAppearance where
    tokenName InfoMessage = "info"
    tokenName WarningMessage = "warning"
    tokenName ErrorMessage = "error"
    tokenName SuccessMessage = "success"
    tokenName DiscoveryMessage = "discovery"

data Message = Message
    { size :: MessageSize
    , appearance :: MessageAppearance
    , title :: Maybe MisoString
    , secondary :: Maybe MisoString
    }

view :: [Attribute action] -> Message -> View model action
view attrs Message{..} =
    a_ (class_ "message" : tokenAttr size : tokenAttr appearance : attrs) . catMaybes $
        [ pure $ span_ [class_ "mdi"] []
        , span_ [class_ "title"] . pure . text <$> title
        , span_ [class_ "secondary"] . pure . text <$> secondary
        ]

style :: Css
style =
    ".message" ? do
        maxWidth $ pct 100
        byToken InlineMessage & do
            clickable
            display inlineFlex
            flexDirection row
            alignItems center
            ".title" ? color' Text
            ".secondary" ? color' TextSubtle
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
            forM_ [minBound .. maxBound] \appearance ->
                byToken appearance & do
                    backgroundColor' $ case appearance of
                        InfoMessage -> BackgroundInformation
                        WarningMessage -> BackgroundWarning
                        SuccessMessage -> BackgroundSuccess
                        ErrorMessage -> BackgroundError
                        DiscoveryMessage -> BackgroundDiscovery
        byToken FormMessage & do
            fontSize (pct 80)
            byToken InfoMessage & ".mdi" ? display none
            marginTop . token $ Space XSmall
        let iconAndText InfoMessage = (MdiInformation, IconBrand, TextSubtle)
            iconAndText WarningMessage = (MdiAlert, IconWarning, TextWarning)
            iconAndText ErrorMessage = (MdiAlertRhombus, IconDanger, TextDanger)
            iconAndText SuccessMessage = (MdiCheckCircle, IconSuccess, TextSuccess)
            iconAndText DiscoveryMessage = (MdiHelpCircle, IconDiscovery, TextDiscovery)
        forM_ [minBound .. maxBound] \appearance ->
            let (mdi, ic, tc) = iconAndText appearance
             in byToken appearance & do
                    byToken FormMessage & color' tc
                    ".mdi" # before ? do
                        content . stringContent . Text.singleton . mdiChar $ mdi
                        color' ic
