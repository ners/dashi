{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Style.Colour
    ( module Dashi.Style.Colour
    , module Graphics.Color.Space
    , module Graphics.Color.Space.OKLAB.LCH
    , module Graphics.Color.Space.RGB.SRGB
    )
where

import Clay ((@=))
import Clay qualified
import Control.Lens (Iso', iso)
import Dashi.Style.Tokens
import Data.Bool (bool)
import Data.Functor ((<&>))
import Data.List qualified as List
import Data.String (IsString, fromString)
import Graphics.Color.Space
    ( Alpha
    , ColorSpace
    , Elevator
    , addAlpha
    , convertColor
    , dropAlpha
    , getAlpha
    , setAlpha
    , toShowS
    )
import Graphics.Color.Space.OKLAB.LCH
import Graphics.Color.Space.RGB.SRGB
import Miso.JSON (FromJSON (..), ToJSON (..), withText)
import Miso.Prelude
import Miso.String (ToMisoString (..))

type Colour = Color OKLCH

type AlphaColour = Color (Alpha OKLCH)

data Scheme = Light | Dark
    deriving stock (Eq, Show, Bounded, Enum)

instance FromJSON Scheme where
    parseJSON = withText "Colour.Scheme" \s ->
        oneOf
            [ pure scheme
            | scheme <- [minBound .. maxBound]
            , s == tokenName scheme
            ]

instance ToJSON Scheme where
    toJSON = toJSON @MisoString . tokenName

isDark :: Iso' Bool Scheme
isDark = iso (bool Light Dark) (== Dark)

instance Token Scheme where
    tokenName Light = "light"
    tokenName Dark = "dark"
    tokenAttr = textProp "data-theme" . tokenName
    byToken = ("data-theme" @=) . tokenName

data LightDark c = LightDark {light :: c, dark :: c}

sameLightDark :: c -> LightDark c
sameLightDark c = LightDark c c

complementaryLightDark
    :: (Num e) => Color (Alpha OKLCH) e -> LightDark (Color (Alpha OKLCH) e)
complementaryLightDark light@(ColorOKLCHA l c h a) = LightDark light $ ColorOKLCHA (1 - l) c h a

flipLightDark :: LightDark c -> LightDark c
flipLightDark LightDark{..} = LightDark{light = dark, dark = light}

getLightDark :: Scheme -> LightDark c -> c
getLightDark Light = light
getLightDark Dark = dark

instance Functor LightDark where
    f `fmap` LightDark{..} = LightDark{light = f light, dark = f dark}

convertAlphaColor
    :: forall cs cs' i e
     . (ColorSpace cs' i e, ColorSpace cs i e)
    => Color (Alpha cs') e -> Color (Alpha cs) e
convertAlphaColor c = addAlpha (convertColor . dropAlpha $ c) (getAlpha c)

fn :: (IsString s) => String -> [ShowS] -> s
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
        fn "rgb"
            $ [toShowS r, toShowS g, toShowS b]
            <> if a == 1 then [] else [showChar '/', toShowS a]

instance (Elevator e) => Clay.Val (Color OKLCH e) where
    value :: Color OKLCH e -> Clay.Value
    value (ColorOKLCH l c h) = fn "oklch" [toShowS l, toShowS c, toShowS h]

instance (Elevator e) => Clay.Val (Color (Alpha OKLCH) e) where
    value :: Color (Alpha OKLCH) e -> Clay.Value
    value (ColorOKLCHA l c h a) =
        fn "oklch"
            $ [toShowS l, toShowS c, toShowS h]
            <> if a == 1 then [] else [showChar '/', toShowS a]

instance (Clay.Val c, Eq c) => Clay.Val (LightDark c) where
    value :: LightDark c -> Clay.Value
    value LightDark{..}
        | light == dark = Clay.value light
        | otherwise = "light-dark(" <> Clay.value light <> "," <> Clay.value dark <> ")"

instance (Num e, Elevator e) => ToMisoString (Color (SRGB l) e) where
    toMisoString :: Color (SRGB l) e -> MisoString
    toMisoString (ColorSRGB ((255 *) -> r) ((255 *) -> g) ((255 *) -> b)) =
        fn "rgb" [toShowS r, toShowS g, toShowS b]

instance (Num e, Elevator e) => ToMisoString (Color (Alpha (SRGB l)) e) where
    toMisoString :: Color (Alpha (SRGB l)) e -> MisoString
    toMisoString (ColorSRGBA ((255 *) -> r) ((255 *) -> g) ((255 *) -> b) a) =
        fn "rgb"
            $ [toShowS r, toShowS g, toShowS b]
            <> if a == 1 then [] else [showChar '/', toShowS a]

instance (Elevator e) => ToMisoString (Color OKLCH e) where
    toMisoString :: Color OKLCH e -> MisoString
    toMisoString (ColorOKLCH l c h) = fn "oklch" [toShowS l, toShowS c, toShowS h]

instance (Elevator e) => ToMisoString (Color (Alpha OKLCH) e) where
    toMisoString :: Color (Alpha OKLCH) e -> MisoString
    toMisoString (ColorOKLCHA l c h a) =
        fn "oklch"
            $ [toShowS l, toShowS c, toShowS h]
            <> if a == 1 then [] else [showChar '/', toShowS a]

instance (ToMisoString c, Eq c) => ToMisoString (LightDark c) where
    toMisoString :: LightDark c -> MisoString
    toMisoString LightDark{..}
        | light == dark = toMisoString light
        | otherwise =
            "light-dark(" <> toMisoString light <> "," <> toMisoString dark <> ")"

toClayColor :: (Clay.Val (Color cs e)) => Color cs e -> Clay.Color
toClayColor = Clay.Other . Clay.value

newtype Text = Text Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Text where
    tokenName (Text appearance) = "text-" <> tokenName appearance

instance ValueToken Text where
    type ValueType Text = LightDark (Color (Alpha OKLCH) Double)
    tokenValue (Text Default) = complementaryLightDark $ ColorOKLCHA 0.197 0.008 264 1
    tokenValue (Text Subtle) = flip setAlpha 0.75 <$> tokenValue (Text Default)
    tokenValue (Text appearance) = LightDark (ColorOKLCHA l c h 1) (ColorOKLCHA l c h 1)
      where
        l, c, h :: Double
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
    type ValueType InverseText = LightDark (Color (Alpha OKLCH) Double)
    tokenValue InverseText = tokenValue (Text Default) <&> \(ColorOKLCHA _ c h a) -> ColorOKLCHA 1 c h a

newtype Background = Background Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Background where
    tokenName (Background appearance) = "background-" <> tokenName appearance

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue (Background Default) = LightDark (ColorOKLCHA 0.932 0.004 256 1) (ColorOKLCHA 0.256 0.011 264 1)
    tokenValue (Background Subtle) = flip setAlpha 0 <$> tokenValue (Background Default)
    tokenValue (Background appearance) =
        tokenValue (Text appearance) <&> \(ColorOKLCHA l c h _) -> ColorOKLCHA l c h 0.15

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
    type ValueType Border = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Border = complementaryLightDark $ ColorOKLCHA 0.1733 0.0136 159.53 0.3
    tokenValue BorderFocused = tokenValue $ Text Primary
    tokenValue BorderDanger = tokenValue $ Text Danger
