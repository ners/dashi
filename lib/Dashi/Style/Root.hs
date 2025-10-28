{-# LANGUAGE AllowAmbiguousTypes #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Root where

import Clay hiding (FontSize, fullWidth, var)
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
        varDecl "transition" $ ([value $ sec 0.2, value easeInOut] :: [Value])
        tokenDecl @Space
        tokenDecl @Radius
        tokenDecl @Colour
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
        disabled & do
            important $ cursor notAllowed
            important $ color' DisabledText
            important $ backgroundColor' DisabledBackground
        ariaBusy True & do
            cursor cursorProgress
    html ? do
        overflowX hidden
        overflowY auto
    body ? do
        font $ var @Value "font-body" ["normal 400 14px/1.4 " <> var "font-family" []]
        color' $ Text Default
