{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Components.Icon where

import Clay (Auto (auto), Content, Css, FontFaceFormat (WOFF2), FontFaceSrc (FontFaceSrcUrl), Normal (normal), display, fontFace, fontFaceSrc, fontFamily, fontStyle, fontWeight, important, inlineBlock, none, stringContent, textDecoration, textRendering, userSelect, (?))
import Dashi.Components.Widget
import Dashi.Style.Util ((~:))
import Data.String (IsString (fromString))
import Data.Text qualified as Text
import Miso
import Miso.Html (span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI, mdiChar)
import Prelude

iconFont :: Css
iconFont = "font" ~: "normal normal normal 1.5em/1 'Material Design Icons'"

iconContent :: MDI -> Content
iconContent = stringContent . Text.singleton . mdiChar

instance Widget MDI model action where
    widget' attrs = span_ (class_ "mdi" : attrs) . pure . text . fromString . pure . mdiChar
    style = do
        fontFace do
            fontFamily ["Material Design Icons"] []
            fontStyle normal
            fontWeight normal
            fontFaceSrc [FontFaceSrcUrl "/static/materialdesignicons-webfont.woff2" (Just WOFF2)]
        ".mdi" ? do
            display inlineBlock
            textRendering auto
            important $ textDecoration none
            iconFont
            userSelect none
