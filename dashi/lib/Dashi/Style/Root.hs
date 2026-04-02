{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Root where

import Clay hiding (Color, FontSize, fullWidth, var)
import Dashi.Style.Background (BackgroundColour (BackgroundColour))
import Dashi.Style.Border (BorderColour)
import Dashi.Style.Colour ()
import Dashi.Style.Text (InverseTextColour, TextColour (TextColour))
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu)
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
        varDecl @Value "font-body" $
            "normal 400 14px/1.5 " <> var "font-family-sans-serif" []
        tokenDecl @Space
        tokenDecl @Radius
        for_ @[] (allTokens @Uchu) \t -> tokenName t ~: value (tokenValue t)
        tokenDecl @TextColour
        tokenDecl @InverseTextColour
        tokenDecl @BackgroundColour
        tokenDecl @BorderColour
        tokenDecl @FontSize
        tokenDecl @BorderWidth
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
    body ? do
        font $ var @Value "font-body" []
        backgroundColor' $ BackgroundColour Default
        color' $ TextColour Default
        has ("#dashi-loading" # onlyChild) & do
            height $ vh 100
            display flex
            justifyContent center
            alignItems center
            "#dashi-loading" ? do
                width $ em 2
                height $ em 2
        "#dashi-loading" ? not onlyChild & display none
