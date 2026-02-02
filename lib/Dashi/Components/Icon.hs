{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Components.Icon
    ( module Dashi.Components.Icon
    , module Web.Font.MDI
    )
where

import Clay hiding (action, span_)
import Dashi.Prelude hiding (none)
import Dashi.Style.Util ((~:))
import Miso.Html (span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI (..), mdiChar)

iconStyle :: Css
iconStyle = do
    "font" ~: "normal normal normal 1.5em/1 'Material Design Icons'"
    userSelect none
    textAlign center
    display inlineBlock
    textRendering auto
    important $ textDecoration none

iconContent :: MDI -> Content
iconContent = stringContent . fromString . pure . mdiChar

type Icon = MDI

instance Widget MDI model action where
    widget' attrs = span_ (class_ "mdi" : attrs) . pure . textRaw . fromString . pure . mdiChar
    style = do
        fontFace do
            fontFamily ["Material Design Icons"] []
            fontStyle normal
            fontWeight normal
            fontFaceSrc
                [FontFaceSrcUrl "/static/materialdesignicons-webfont.woff2" (Just WOFF2)]
        ".mdi" ? iconStyle
