{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Style.Uchu where

import Clay qualified
import Dashi.Style.Colour ()
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util (colorToken')
import Dashi.Util (breakAll, uncapitalise)
import Data.Char (isDigit, isUpper)
import Data.Fixed (Fixed, HasResolution, Micro, showFixed)
import Data.String (IsString (fromString))
import Graphics.Color.Space
import Graphics.Color.Space.OKLAB.LCH (OKLCH)
import Graphics.Color.Uchu hiding (Uchu, uchu)
import Graphics.Color.Uchu.Extended qualified as Extended
import Graphics.Color.Uchu.Extended.OKLCH qualified as Extended
import Graphics.Color.Uchu.Simple qualified as Simple
import Graphics.Color.Uchu.Simple.OKLCH qualified as Simple
import Miso.String (fromMisoString, toMisoString)
import Miso.String qualified as MisoString
import Prelude

data Uchu
    = Gray1
    | Gray2
    | Gray3
    | Gray4
    | Gray5
    | Gray6
    | Gray7
    | Gray8
    | Gray9
    | Gray
    | LightGray
    | DarkGray
    | Red1
    | Red2
    | Red3
    | Red4
    | Red5
    | Red6
    | Red7
    | Red8
    | Red9
    | Red
    | LightRed
    | DarkRed
    | Pink1
    | Pink2
    | Pink3
    | Pink4
    | Pink5
    | Pink6
    | Pink7
    | Pink8
    | Pink9
    | Pink
    | LightPink
    | DarkPink
    | Purple1
    | Purple2
    | Purple3
    | Purple4
    | Purple5
    | Purple6
    | Purple7
    | Purple8
    | Purple9
    | Purple
    | LightPurple
    | DarkPurple
    | Blue1
    | Blue2
    | Blue3
    | Blue4
    | Blue5
    | Blue6
    | Blue7
    | Blue8
    | Blue9
    | Blue
    | LightBlue
    | DarkBlue
    | Green1
    | Green2
    | Green3
    | Green4
    | Green5
    | Green6
    | Green7
    | Green8
    | Green9
    | Green
    | LightGreen
    | DarkGreen
    | Yellow1
    | Yellow2
    | Yellow3
    | Yellow4
    | Yellow5
    | Yellow6
    | Yellow7
    | Yellow8
    | Yellow9
    | Yellow
    | LightYellow
    | DarkYellow
    | Orange1
    | Orange2
    | Orange3
    | Orange4
    | Orange5
    | Orange6
    | Orange7
    | Orange8
    | Orange9
    | Orange
    | LightOrange
    | DarkOrange
    | Yin1
    | Yin2
    | Yin3
    | Yin4
    | Yin5
    | Yin6
    | Yin7
    | Yin8
    | Yin9
    | Yin
    | LightYin
    | Yang
    deriving stock (Eq, Bounded, Enum, Show)

uchu :: (Fractional e) => Uchu -> Color OKLCH e
uchu Gray1 = _1 Extended.uchu.gray
uchu Gray2 = _2 Extended.uchu.gray
uchu Gray3 = _3 Extended.uchu.gray
uchu Gray4 = _4 Extended.uchu.gray
uchu Gray5 = _5 Extended.uchu.gray
uchu Gray6 = _6 Extended.uchu.gray
uchu Gray7 = _7 Extended.uchu.gray
uchu Gray8 = _8 Extended.uchu.gray
uchu Gray9 = _9 Extended.uchu.gray
uchu Gray = base Simple.uchu.gray
uchu LightGray = light Simple.uchu.gray
uchu DarkGray = dark Simple.uchu.gray
uchu Red1 = _1 Extended.uchu.red
uchu Red2 = _2 Extended.uchu.red
uchu Red3 = _3 Extended.uchu.red
uchu Red4 = _4 Extended.uchu.red
uchu Red5 = _5 Extended.uchu.red
uchu Red6 = _6 Extended.uchu.red
uchu Red7 = _7 Extended.uchu.red
uchu Red8 = _8 Extended.uchu.red
uchu Red9 = _9 Extended.uchu.red
uchu Red = base Simple.uchu.red
uchu LightRed = light Simple.uchu.red
uchu DarkRed = dark Simple.uchu.red
uchu Pink1 = _1 Extended.uchu.pink
uchu Pink2 = _2 Extended.uchu.pink
uchu Pink3 = _3 Extended.uchu.pink
uchu Pink4 = _4 Extended.uchu.pink
uchu Pink5 = _5 Extended.uchu.pink
uchu Pink6 = _6 Extended.uchu.pink
uchu Pink7 = _7 Extended.uchu.pink
uchu Pink8 = _8 Extended.uchu.pink
uchu Pink9 = _9 Extended.uchu.pink
uchu Pink = base Simple.uchu.pink
uchu LightPink = light Simple.uchu.pink
uchu DarkPink = dark Simple.uchu.pink
uchu Purple1 = _1 Extended.uchu.purple
uchu Purple2 = _2 Extended.uchu.purple
uchu Purple3 = _3 Extended.uchu.purple
uchu Purple4 = _4 Extended.uchu.purple
uchu Purple5 = _5 Extended.uchu.purple
uchu Purple6 = _6 Extended.uchu.purple
uchu Purple7 = _7 Extended.uchu.purple
uchu Purple8 = _8 Extended.uchu.purple
uchu Purple9 = _9 Extended.uchu.purple
uchu Purple = base Simple.uchu.purple
uchu LightPurple = light Simple.uchu.purple
uchu DarkPurple = dark Simple.uchu.purple
uchu Blue1 = _1 Extended.uchu.blue
uchu Blue2 = _2 Extended.uchu.blue
uchu Blue3 = _3 Extended.uchu.blue
uchu Blue4 = _4 Extended.uchu.blue
uchu Blue5 = _5 Extended.uchu.blue
uchu Blue6 = _6 Extended.uchu.blue
uchu Blue7 = _7 Extended.uchu.blue
uchu Blue8 = _8 Extended.uchu.blue
uchu Blue9 = _9 Extended.uchu.blue
uchu Blue = base Simple.uchu.blue
uchu LightBlue = light Simple.uchu.blue
uchu DarkBlue = dark Simple.uchu.blue
uchu Green1 = _1 Extended.uchu.green
uchu Green2 = _2 Extended.uchu.green
uchu Green3 = _3 Extended.uchu.green
uchu Green4 = _4 Extended.uchu.green
uchu Green5 = _5 Extended.uchu.green
uchu Green6 = _6 Extended.uchu.green
uchu Green7 = _7 Extended.uchu.green
uchu Green8 = _8 Extended.uchu.green
uchu Green9 = _9 Extended.uchu.green
uchu Green = base Simple.uchu.green
uchu LightGreen = light Simple.uchu.green
uchu DarkGreen = dark Simple.uchu.green
uchu Yellow1 = _1 Extended.uchu.yellow
uchu Yellow2 = _2 Extended.uchu.yellow
uchu Yellow3 = _3 Extended.uchu.yellow
uchu Yellow4 = _4 Extended.uchu.yellow
uchu Yellow5 = _5 Extended.uchu.yellow
uchu Yellow6 = _6 Extended.uchu.yellow
uchu Yellow7 = _7 Extended.uchu.yellow
uchu Yellow8 = _8 Extended.uchu.yellow
uchu Yellow9 = _9 Extended.uchu.yellow
uchu Yellow = base Simple.uchu.yellow
uchu LightYellow = light Simple.uchu.yellow
uchu DarkYellow = dark Simple.uchu.yellow
uchu Orange1 = _1 Extended.uchu.orange
uchu Orange2 = _2 Extended.uchu.orange
uchu Orange3 = _3 Extended.uchu.orange
uchu Orange4 = _4 Extended.uchu.orange
uchu Orange5 = _5 Extended.uchu.orange
uchu Orange6 = _6 Extended.uchu.orange
uchu Orange7 = _7 Extended.uchu.orange
uchu Orange8 = _8 Extended.uchu.orange
uchu Orange9 = _9 Extended.uchu.orange
uchu Orange = base Simple.uchu.orange
uchu LightOrange = light Simple.uchu.orange
uchu DarkOrange = dark Simple.uchu.orange
uchu Yin1 = _1 Extended.yin
uchu Yin2 = _2 Extended.yin
uchu Yin3 = _3 Extended.yin
uchu Yin4 = _4 Extended.yin
uchu Yin5 = _5 Extended.yin
uchu Yin6 = _6 Extended.yin
uchu Yin7 = _7 Extended.yin
uchu Yin8 = _8 Extended.yin
uchu Yin9 = _9 Extended.yin
uchu Yin = Simple.yin
uchu LightYin = Simple.lightYin
uchu Yang = Simple.yang

instance Token Uchu where
    tokenName =
        fromString
            . fromMisoString
            . ("--uchu-" <>)
            . MisoString.intercalate "-"
            . fmap uncapitalise
            . breakAll (\c -> isUpper c || isDigit c)
            . toMisoString
            . show

instance ValueToken Uchu where
    type ValueType Uchu = Color OKLCH Micro
    tokenValue = uchu

instance Clay.Val Uchu where
    value :: Uchu -> Clay.Value
    value = Clay.value . colorToken'

data UchuAlpha a = UchuAlpha Uchu a

instance (Num a, Eq a) => Eq (UchuAlpha a) where
    (UchuAlpha u1 a1) == (UchuAlpha u2 a2)
        | a1 == 0 && a2 == 0 = True
        | otherwise = u1 == u2 && a1 == a2

uchuAlpha :: (Fractional e) => UchuAlpha e -> Color (Alpha OKLCH) e
uchuAlpha (UchuAlpha u a) = addAlpha (uchu u) a

setAlpha :: a -> UchuAlpha a -> UchuAlpha a
setAlpha a (UchuAlpha u _) = UchuAlpha u a

instance (HasResolution e) => Clay.Val (UchuAlpha (Fixed e)) where
    value :: UchuAlpha (Fixed e) -> Clay.Value
    value (UchuAlpha u a)
        | a == 0 = "transparent"
        | a == 1 = fromString var
        | otherwise =
            Colour.fn'
                "oklch"
                [ "from"
                , var
                , "l"
                , "c"
                , "h"
                , "/"
                , showFixed True a
                ]
      where
        var = "var(" <> tokenName u <> ")"
