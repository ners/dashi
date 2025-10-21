module Dashi.Components.Icon where

import Clay (Auto (auto), Css, FontFaceFormat (WOFF2), FontFaceSrc (FontFaceSrcUrl), Normal (normal), display, fontFace, fontFaceSrc, fontFamily, fontStyle, fontWeight, important, inlineBlock, none, textDecoration, textRendering, (?))
import Dashi.Style.Util ((~:))
import Data.String (IsString (fromString))
import Miso
import Miso.Html (span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI, mdiChar)
import Prelude

style :: Css
style = do
    fontFace do
        fontFamily ["Material Design Icons"] []
        fontStyle normal
        fontWeight normal
        fontFaceSrc [FontFaceSrcUrl "materialdesignicons-webfont.woff2" (Just WOFF2)]

    ".mdi" ? do
        display inlineBlock
        textRendering auto
        important $ textDecoration none
        "font" ~: "normal normal normal 1.5em/1 'Material Design Icons'"

icon :: [Attribute action] -> MDI -> View model action
icon attrs = span_ (class_ "mdi" : attrs) . pure . text . fromString . pure . mdiChar
