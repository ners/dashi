{-# LANGUAGE PatternSynonyms #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Colours where

import Dashi.Components.Heading
import Dashi.Prelude hiding (Simple, update, view)
import Dashi.Style.Colour (Linearity (..), SRGB, pattern ColorSRGB)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu, uchu)
import Dashi.Util (breakAll, capitalise)
import Data.Char (isDigit, isUpper)
import Data.List qualified as List
import Data.Word (Word8)
import Miso.Html.Element
    ( a_
    , p_
    , section_
    , table_
    , tbody_
    , td_
    , th_
    , thead_
    , tr_
    )
import Miso.Html.Property (href_)
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
                "Dashi builds on top of the "
            , a_ [href_ "https://uchu.style"] [text "the uchū colour palette"]
            , text " to create consistency in apps."
            ]
        , widget $ Heading Medium "Simple"
        , table_
            []
            [ thead_
                []
                [ th_ [] [text "Colour"]
                , th_ [] [text "OKLCH"]
                , th_ [] [text "RGB"]
                , th_ [] [text "Hex"]
                ]
            , tbody_ [] $ row <$> simples
            ]
        , widget $ Heading Medium "Extended"
        , table_
            []
            [ thead_
                []
                [ th_ [] [text "Colour"]
                , th_ [] [text "OKLCH"]
                , th_ [] [text "RGB"]
                , th_ [] [text "Hex"]
                ]
            , tbody_ [] $ row <$> expandeds
            ]
        ]

simples, expandeds :: [Uchu]
(expandeds, simples) = List.partition (isDigit . last . tokenName) [minBound .. maxBound]

row :: Uchu -> View Model Action
row u =
    tr_
        []
        [ td_
            []
            [ text
                . capitalise
                . MisoString.intercalate " "
                . breakAll (\c -> isUpper c || isDigit c)
                . ishow
                $ u
            ]
        , td_ [] [text . toMisoString $ oklch]
        , td_ [] [text rgbDec]
        , td_ [] [text rgbHex]
        ]
  where
    oklch = uchu @Micro u
    ColorSRGB r g b = Colour.convertColor @(SRGB 'NonLinear) $ uchu @Double u
    rgbDec = "rgb(" <> dec r <> "," <> dec g <> "," <> dec b <> ")"
    rgbHex = "#" <> hex r <> hex g <> hex b
    word8 :: Double -> Word8
    word8 = round @_ @Word8 . (* 255)
    dec, hex :: Double -> MisoString
    dec = ishow . word8
    hex = toMisoString @String . printf "%02X" . word8
