{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Root where

import Clay hiding (Color, FontSize, fullWidth, var)
import Dashi.Style.Colour ()
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Foldable (for_)
import Data.Text (Text)
import Prelude hiding (div, not, rem, (**))

varDecl' :: Key Text -> Value -> Css
varDecl' n v = varName n ~: v

varDecl :: (Val v) => Key Text -> v -> Css
varDecl n = varDecl' n . value

tokenDecl :: forall t. (ValueToken t, Val (ValueType t)) => Css
tokenDecl = for_ @[] (allTokens @t) \t -> varDecl (tokenName t) (tokenValue t)

style :: Css
style = do
    ":root" ? do
        varDecl @[Value]
            "font-family-emoji"
            [ "'Apple Color Emoji'"
            , "'Segoe UI Emoji'"
            , "'Segoe UI Symbol'"
            , "'Noto Color Emoji'"
            ]
        varDecl @[Value]
            "font-family-sans-serif"
            [ "system-ui"
            , "-apple-system"
            , "BlinkMacSystemFont"
            , "'Segoe UI'"
            , "Roboto"
            , "Oxygen"
            , "Ubuntu"
            , "'Fira Sans'"
            , "'Droid Sans'"
            , "'Helvetica Neue'"
            , "sans-serif"
            , var "font-family-emoji" []
            ]
        varDecl @[Value]
            "font-family-monospace"
            [ "ui-monospace"
            , "SFMono-Regular"
            , "'SF Mono'"
            , "'Segou UI Mono'"
            , "'Liberation Mono'"
            , "'Ubuntu Mono'"
            , "Menlo"
            , "Consolas"
            , "monospace"
            , var "font-family-emoji" []
            ]
        varDecl "font-family" $ var @Value "font-family-sans-serif" []
        varDecl "line-height" $ unitless 1.5
        varDecl "font-weight" $ weight 400
        varDecl "font-size" $ pct 100
        varDecl "text-underline-offset" $ rem 0.1
        varDecl "border-radius" $ rem 0.25
        varDecl "border-width" $ rem 0.0625
        varDecl "outline-width" $ rem 0.125
        varDecl "transition" ([value $ sec 0.2, value easeInOut] :: [Value])
        tokenDecl @Space
        tokenDecl @Radius
        tokenDecl @Colour.Text
        tokenDecl @Colour.InverseText
        tokenDecl @Colour.Background
        tokenDecl @Colour.Border
        tokenDecl @FontSize
    star ? do
        marginAll nil
        paddingAll nil
        fontFamily [] [inherit]
        Clay.fontSize inherit
        fontStyle inherit
        fontWeight inherit
        color inherit
        textDecoration inherit
        boxSizing borderBox
        lineHeight inherit
        "border" ~: none
        "background" ~: none
        "appearance" ~: none
        "-webkit-appearance" ~: none
        "-moz-appearance" ~: none
        ariaBusy True & do
            cursor cursorProgress
    let anyDisabledElement = self # disabled
    (self # disabled <> label # has (self |> anyDisabledElement)) ? do
        important $ cursor notAllowed
        opacity 0.5
        "filter" -: "grayscale(100%)"
    html ? do
        overflowX hidden
        overflowY auto
        byTokens @Colour.Scheme \scheme -> "color-scheme" -: tokenName scheme
    body ? do
        font $
            var @Value
                "font-body"
                ["normal " <> var "font-weight" [] <> " 14px/1.4 " <> var "font-family" []]
        backgroundColor' $ Colour.Background Default
        color' $ Colour.Text Default
        Clay.not (has "*") & do
            height $ vh 100
            display flex
            justifyContent center
            alignItems center
            before & do
                display block
                content (stringContent "Loading...")
