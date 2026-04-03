{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Components.Icon
    ( module Dashi.Components.Icon
    , Phosphor (..)
    )
where

import Clay hiding (action, span_)
import Dashi.Prelude hiding (has, none, span, (&))
import Dashi.Style.Tokens (Token (..), byTokens)
import Dashi.Style.Util ((~:))
import Data.Char (toLower)
import Miso.Html (span_)
import Miso.Html.Property (class_)
import Web.Font.Phosphor (Phosphor (..))
import Web.Font.Phosphor qualified as Phosphor

data Weight = Thin | Light | Regular | Bold | Fill | Duotone
    deriving stock (Eq, Show, Bounded, Enum)

instance Token Weight where
    tokenName = fromString . fmap toLower . ishow
    defaultToken = Just Regular

fontName :: forall s. (IsString s) => Weight -> s
fontName w
    | Just w == defaultToken = "Phosphor"
    | otherwise = fromString $ "Phosphor-" <> show w

data Icon = Icon Weight Phosphor

iconFontFamilyOverride :: Weight -> Css
iconFontFamilyOverride Regular = pure ()
iconFontFamilyOverride weight =
    -- important prevents issues with browser extensions that change fonts
    important $ "font-family" ~: fontName weight

iconStyle :: Css
iconStyle = do
    "font-family" -: fontName Regular
    "speak" -: "never"
    "font-style" -: "normal"
    "font-weight" -: "normal"
    "font-variant" -: "normal"
    "text-transform" -: "none"
    fontSize $ pct 110
    lineHeight $ unitless 1
    userSelect none
    textAlign center
    display inlineBlock
    textRendering auto
    important $ textDecoration none
    position relative
    top $ em 0.05

iconContent :: Phosphor -> Content
iconContent = stringContent . fromString . pure . Phosphor.char

instance Widget Icon model action where
    widget' attrs (Icon weight icon) =
        span_ (class_ "icon" : tokenAttr weight : attrs)
            . pure
            . textRaw
            . fromString
            . pure
            . Phosphor.char
            $ icon
    style = do
        for_ [minBound .. maxBound] \weight ->
            fontFace do
                fontFamily [fontName weight] []
                fontStyle normal
                fontWeight normal
                fontFaceSrc
                    [ FontFaceSrcUrl ("/static/phosphor/" <> fontName weight <> ".woff2") (Just WOFF2)
                    , FontFaceSrcUrl ("/static/phosphor/" <> fontName weight <> ".woff") (Just WOFF)
                    , FontFaceSrcUrl
                        ("/static/phosphor/" <> fontName weight <> ".ttf")
                        (Just TrueType)
                    ]
        ".icon" ? do
            iconStyle
            byTokens iconFontFamilyOverride
            ".inline" & marginRight (em 0.2)

inlineIcon :: Icon -> View model action
inlineIcon = widget' [class_ "inline"]
