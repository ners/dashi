{-# LANGUAGE PatternSynonyms #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Colours where

import Dashi.Components.Heading
import Dashi.Prelude hiding (Simple, simple, update, view)
import Dashi.Style.Colour
    ( Color
    , Linearity (..)
    , OKLCH
    , SRGB
    , pattern ColorOKLCH
    , pattern ColorSRGB
    )
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Data.Word (Word8)
import Graphics.Color.Uchu
import Graphics.Color.Uchu.Simple.OKLCH ()
import Miso.CSS (styleInline_)
import Miso.Html.Element
    ( a_
    , div_
    , li_
    , p_
    , section_
    , ul_
    )
import Miso.Html.Property (class_, href_, target_)
import Miso.String qualified as MisoString
import Text.Printf (printf)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

colours :: Component parent Model Action
colours = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Colours"
        , p_
            []
            [ text
                "Colours establish hierarchy, convey meaning, and shape the overall tone of an interface. They guide attention, differentiate elements, and help users understand states and feedback at a glance."
            ]
        , p_
            []
            [ text
                "Dashi uses the "
            , a_ [href_ "https://uchu.style", target_ "blank"] [text "uchū colour palette"]
            , text
                ", a soothing pastel palette designed to give interfaces a calm, approachable, and cohesive appearance."
            ]
        , widget $ Heading Medium "Simple"
        , ul_
            [class_ "palette"]
            [ simple "Gray" uchu.gray
            , simple "Red" uchu.red
            , simple "Pink" uchu.pink
            , simple "Purple" uchu.purple
            , simple "Blue" uchu.blue
            , simple "Green" uchu.green
            , simple "Yellow" uchu.yellow
            , simple "Orange" uchu.orange
            ]
        , widget $ Heading Medium "Extended"
        , ul_
            [class_ "palette"]
            [ extended "Gray" uchu.gray
            , extended "Red" uchu.red
            , extended "Pink" uchu.pink
            , extended "Purple" uchu.purple
            , extended "Blue" uchu.blue
            , extended "Green" uchu.green
            , extended "Yellow" uchu.yellow
            , extended "Orange" uchu.orange
            ]
        ]

simple :: MisoString -> Simple OKLCH Micro -> View Model Action
simple name oklch =
    li_
        []
        [ widget $ Heading Small name
        , ul_
            [class_ "colour"]
            [ shade "Light"
            , shade "Base"
            , shade "Dark"
            ]
        ]
  where
    shade prefix =
        let
            bg, fg :: MisoString
            bg = "background-color: " <> var prefix
            fg =
                case prefix of
                    "Dark" -> "color: var(--uchu-yang)"
                    _ -> "color: var(--uchu-yin)"
         in
            li_
                [ class_ "shade"
                , styleInline_ $ MisoString.intercalate ";" [bg, fg]
                ]
                [ div_ [class_ "name"] [text prefix]
                , codes
                    $ case prefix of
                        "Dark" -> oklch.dark
                        "Light" -> oklch.light
                        _ -> oklch.base
                ]
    var "Base" = "var(--uchu-" <> MisoString.toLower name <> ")"
    var prefix =
        "var(--uchu-"
            <> MisoString.toLower prefix
            <> "-"
            <> MisoString.toLower name
            <> ")"

extended :: MisoString -> Extended OKLCH Micro -> View Model Action
extended name oklch =
    li_
        []
        [ widget $ Heading Small name
        , ul_
            [class_ "colour"]
            $ shade
            <$> [1 .. 9]
        ]
  where
    shade :: Int -> View Model Action
    shade i =
        let
            bg, fg :: MisoString
            bg = "background-color: " <> var i
            fg =
                if i > 5
                    then "color: var(--uchu-yang)"
                    else "color: var(--uchu-yin)"
         in
            li_
                [ class_ "shade"
                , styleInline_ $ MisoString.intercalate ";" [bg, fg]
                ]
                [ div_ [class_ "name"] [text $ toMisoString i]
                , codes
                    $ case i of
                        1 -> oklch._1
                        2 -> oklch._2
                        3 -> oklch._3
                        4 -> oklch._4
                        5 -> oklch._5
                        6 -> oklch._6
                        7 -> oklch._7
                        8 -> oklch._8
                        _ -> oklch._9
                ]
    var i =
        "var(--uchu-"
            <> MisoString.toLower name
            <> "-"
            <> toMisoString i
            <> ")"

codes :: Color OKLCH Micro -> View Model Action
codes oklch =
    ul_
        [class_ "codes"]
        [ li_ [] [text $ toMisoString oklch]
        , li_ [] [text rgbDec]
        , li_ [] [text rgbHex]
        ]
  where
    ColorSRGB r g b =
        Colour.convertColor @(SRGB 'NonLinear)
            $ let ColorOKLCH l c h = oklch
               in ColorOKLCH (realToFrac l) (realToFrac c) (realToFrac h)
    rgbDec = "rgb(" <> dec r <> "," <> dec g <> "," <> dec b <> ")"
    rgbHex = "#" <> hex r <> hex g <> hex b
    word8 :: Double -> Word8
    word8 = round @_ @Word8 . (* 255)
    dec, hex :: Double -> MisoString
    dec = ishow . word8
    hex = toMisoString @String . printf "%02X" . word8
