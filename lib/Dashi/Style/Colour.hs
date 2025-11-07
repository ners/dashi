{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Style.Colour where

import Clay qualified
import Dashi.Style.Tokens
import Data.List qualified as List
import Data.String (fromString)
import Graphics.Color.Space hiding (Primary)
import Graphics.Color.Space.OKLAB.LCH
import Prelude

convertAlphaColor :: forall cs cs' i e. (ColorSpace cs' i e, ColorSpace cs i e) => Color (Alpha cs') e -> Color (Alpha cs) e
convertAlphaColor c = addAlpha (convertColor . dropAlpha $ c) (getAlpha c)

fn :: String -> [ShowS] -> Clay.Value
fn name args = fromString . mconcat $ [name, "(", unwords (showMilli <$> args), ")"]
  where
    showMilli :: ShowS -> String
    showMilli = shorten . take 8 . ($ "")
    shorten :: String -> String
    shorten s
        | '.' `elem` s = List.dropWhileEnd (== '.') . List.dropWhileEnd (== '0') $ s
        | otherwise = s

instance (Num e, Elevator e) => Clay.Val (Color (SRGB l) e) where
    value :: Color (SRGB l) e -> Clay.Value
    value (ColorSRGB ((255 *) -> r) ((255 *) -> g) ((255 *) -> b)) =
        fn "rgb" [toShowS r, toShowS g, toShowS b]

instance (Num e, Elevator e) => Clay.Val (Color (Alpha (SRGB l)) e) where
    value :: Color (Alpha (SRGB l)) e -> Clay.Value
    value (ColorSRGBA ((255 *) -> r) ((255 *) -> g) ((255 *) -> b) a) =
        fn "rgb" $ [toShowS r, toShowS g, toShowS b] <> if a == 1 then [] else [showChar '/', toShowS a]

instance (Elevator e) => Clay.Val (Color OKLCH e) where
    value :: Color OKLCH e -> Clay.Value
    value (ColorOKLCH l c h) = fn "oklch" [toShowS l, toShowS c, toShowS h]

instance (Elevator e) => Clay.Val (Color (Alpha OKLCH) e) where
    value :: Color (Alpha OKLCH) e -> Clay.Value
    value (ColorOKLCHA l c h a) = fn "oklch" $ [toShowS l, toShowS c, toShowS h] <> if a == 1 then [] else [showChar '/', toShowS a]

toClayColor :: (Clay.Val (Color cs e)) => Color cs e -> Clay.Color
toClayColor = Clay.Other . Clay.value

newtype Text = Text Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Text where
    tokenName (Text appearance) = "text-" <> tokenName appearance

instance ValueToken Text where
    type ValueType Text = Color (Alpha OKLCH) Float
    tokenValue (Text Default) = ColorOKLCHA 0.197 0.008 264 1
    tokenValue (Text Subtle) = setAlpha (tokenValue $ Text Default) 0.8
    tokenValue (Text appearance) = ColorOKLCHA l c h 1
      where
        l, c, h :: Float
        l =
            case appearance of
                Warning -> 0.695
                _ -> 0.65
        c = 0.18
        h =
            case appearance of
                Primary -> 255
                Success -> 165
                Warning -> 44
                Danger -> 33
                Discovery -> 320

data InverseText = InverseText
    deriving stock (Eq, Bounded, Enum)

instance Token InverseText where
    tokenName InverseText = "text-inverse"

instance ValueToken InverseText where
    type ValueType InverseText = Color (Alpha OKLCH) Float
    tokenValue InverseText = setAlpha (tokenValue $ Background Default) 1

newtype Background = Background Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Background where
    tokenName (Background appearance) = "background-" <> tokenName appearance

instance ValueToken Background where
    type ValueType Background = Color (Alpha OKLCH) Float
    tokenValue (Background Default) = ColorOKLCHA 1 0 0 0
    tokenValue (Background Subtle) = ColorOKLCHA 1 0 0 0
    tokenValue (Background appearance) =
        let ColorOKLCHA l c h _ = tokenValue $ Text appearance
         in ColorOKLCHA l c h 0.15

data Border
    = Border
    | BorderFocused
    | BorderDanger
    deriving stock (Eq, Bounded, Enum)

instance Token Border where
    tokenName Border = "border-color"
    tokenName BorderFocused = "border-focused-color"
    tokenName BorderDanger = "border-danger-color"

instance ValueToken Border where
    type ValueType Border = Color (Alpha OKLCH) Float
    tokenValue Border = ColorOKLCHA 0.1733 0.0136 159.53 0.3
    tokenValue BorderFocused = tokenValue $ Text Primary
    tokenValue BorderDanger = tokenValue $ Text Danger
