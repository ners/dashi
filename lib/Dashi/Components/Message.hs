{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Message where

import Clay hiding (span_, title)
import Control.Monad (forM, forM_)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Maybe (maybeToList)
import Data.Text qualified as Text
import Miso
import Miso.Html.Element (a_, span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI (MdiAlert, MdiAlertRhombus, MdiCheckCircle, MdiInformation), mdiChar)
import Prelude

data MessageAppearance
    = WarningMessage
    | ErrorMessage
    | ConfirmationMessage
    | InfoMessage
    deriving stock (Eq, Bounded, Enum, Show)

instance Token MessageAppearance where
    tokenName WarningMessage = "warning"
    tokenName ErrorMessage = "error"
    tokenName ConfirmationMessage = "confirmation"
    tokenName InfoMessage = "info"

messageAppearance :: MessageAppearance -> Attribute action
messageAppearance = class_ . tokenName

message :: [Attribute action] -> Maybe MisoString -> Maybe MisoString -> View model action
message attrs title secondary =
    a_ (class_ "message" : attrs) . mconcat $
        [ pure $ span_ [class_ "mdi"] []
        , span_ [class_ "title"] . pure . text <$> maybeToList title
        , span_ [class_ "secondary"] . pure . text <$> maybeToList secondary
        ]

style :: Css
style =
    ".message" ? do
        clickable
        display inlineFlex
        flexDirection row
        alignItems center
        maxWidth $ pct 100
        gap' XSmall
        fontWeight $ weight 500
        ".title" ? color' Text
        ".secondary" ? color' TextSubtle
        let icon Nothing = (MdiAlert, IconBrand)
            icon (Just WarningMessage) = (MdiAlert, IconWarning)
            icon (Just ErrorMessage) = (MdiAlertRhombus, IconDanger)
            icon (Just ConfirmationMessage) = (MdiCheckCircle, IconSuccess)
            icon (Just InfoMessage) = (MdiInformation, IconDiscovery)
        forM_ (Nothing : (Just <$> [minBound .. maxBound])) \appearance ->
            let ref
                    | Just a <- appearance = (&) $ byClass (tokenName a)
                    | otherwise = Prelude.id
                (i, c) = icon appearance
             in ref $
                    ".mdi" # before ? do
                        content . stringContent . Text.singleton . mdiChar $ i
                        color' c
