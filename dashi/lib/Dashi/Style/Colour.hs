{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Style.Colour
    ( module Dashi.Style.Colour
    , module Graphics.Color.Space
    , module Graphics.Color.Space.OKLAB.LCH
    , module Graphics.Color.Space.RGB.SRGB
    , module Graphics.Color.Adaptation.VonKries
    )
where

import Clay qualified
import Control.Lens (Iso', iso)
import Data.Bifunctor (first)
import Data.Bool (bool)
import Data.Char (toUpper)
import Data.Either.Extra (eitherToMaybe, maybeToEither)
import Data.Fixed (Fixed, HasResolution, showFixed)
import Data.List qualified as List
import Data.String (IsString, fromString)
import Data.Word (Word8)
import Graphics.Color.Adaptation.VonKries (convert)
import Graphics.Color.Space
    ( Alpha
    , ColorSpace
    , Elevator
    , Linearity (..)
    , addAlpha
    , convertColor
    , dropAlpha
    , getAlpha
    , setAlpha
    , toShowS
    )
import Graphics.Color.Space.OKLAB.LCH
import Graphics.Color.Space.RGB.SRGB
import Miso.JSON (FromJSON (..), Parser (..), ToJSON (..), withText)
import Miso.Prelude
import Miso.String (FromMisoString (..), ToMisoString (..))
import Numeric (showHex)

type Colour = Color OKLCH

type AlphaColour = Color (Alpha OKLCH)

data Scheme = Light | Dark
    deriving stock (Eq, Show, Bounded, Enum)

instance FromMisoString Scheme where
    fromMisoStringEither s =
        maybeToEither "invalid colour scheme"
            $ List.find ((s ==) . toMisoString) [minBound .. maxBound]

instance ToMisoString Scheme where
    toMisoString Light = "light"
    toMisoString Dark = "dark"

instance FromJSON Scheme where
    parseJSON = withText "Colour.Scheme" $ Parser . first toMisoString . fromMisoStringEither

instance ToJSON Scheme where
    toJSON = toJSON . toMisoString

instance FromJSVal Scheme where
    fromJSVal = fmap (eitherToMaybe . fromMisoStringEither =<<) . fromJSVal

instance ToJSVal Scheme where
    toJSVal = toJSVal . toMisoString

isDark :: Iso' Scheme Bool
isDark = iso (== Dark) (bool Light Dark)

data LightDark c = LightDark {light :: c, dark :: c}

sameLightDark :: c -> LightDark c
sameLightDark c = LightDark c c

complementaryLightDark
    :: (Num e)
    => Color (Alpha OKLCH) e
    -> LightDark (Color (Alpha OKLCH) e)
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

fn' :: (IsString s) => String -> [String] -> s
fn' name args = fromString . mconcat $ [name, "(", unwords args, ")"]

fn :: (IsString s) => String -> [ShowS] -> s
fn name args = fn' name (showMilli <$> args)
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

-- instance (Elevator e) => Clay.Val (Color OKLCH e) where
--     value :: Color OKLCH e -> Clay.Value
--     value (ColorOKLCH l c h) = fn "oklch" [toShowS l, toShowS c, toShowS h]

instance (HasResolution a) => Clay.Val (Color OKLCH (Fixed a)) where
    value :: Color OKLCH (Fixed a) -> Clay.Value
    value (ColorOKLCH l c h) = fn' "oklch" [showFixed True l, showFixed True c, showFixed True h]

-- instance (Elevator e) => Clay.Val (Color (Alpha OKLCH) e) where
--     value :: Color (Alpha OKLCH) e -> Clay.Value
--     value (ColorOKLCHA l c h a) =
--         fn "oklch"
--             $ [toShowS l, toShowS c, toShowS h]
--             <> if a == 1 then [] else [showChar '/', toShowS a]

instance (HasResolution a) => Clay.Val (Color (Alpha OKLCH) (Fixed a)) where
    value :: Color (Alpha OKLCH) (Fixed a) -> Clay.Value
    value (ColorOKLCHA l c h a) =
        fn' "oklch"
            $ [showFixed True l, showFixed True c, showFixed True h]
            <> ['/' : showFixed True a | a /= 1]

instance (Clay.Val c, Eq c) => Clay.Val (LightDark c) where
    value :: LightDark c -> Clay.Value
    value LightDark{..}
        | light == dark = Clay.value light
        | otherwise = "light-dark(" <> Clay.value light <> "," <> Clay.value dark <> ")"

-- instance (Num e, Elevator e) => ToMisoString (Color (SRGB l) e) where
--     toMisoString :: Color (SRGB l) e -> MisoString
--     toMisoString (ColorSRGB ((255 *) -> r) ((255 *) -> g) ((255 *) -> b)) =
--         fn "rgb" [toShowS r, toShowS g, toShowS b]

instance (HasResolution a) => ToMisoString (Color (SRGB l) (Fixed a)) where
    toMisoString :: Color (SRGB l) (Fixed a) -> MisoString
    toMisoString (ColorSRGB ((255 *) -> r) ((255 *) -> g) ((255 *) -> b)) =
        fn' "rgb" [showFixed True r, showFixed True g, showFixed True b]

-- instance (Num e, Elevator e) => ToMisoString (Color (Alpha (SRGB l)) e) where
--     toMisoString :: Color (Alpha (SRGB l)) e -> MisoString
--     toMisoString (ColorSRGBA ((255 *) -> r) ((255 *) -> g) ((255 *) -> b) a) =
--         fn "rgb"
--             $ [toShowS r, toShowS g, toShowS b]
--             <> if a == 1 then [] else [showChar '/', toShowS a]

instance (HasResolution a) => ToMisoString (Color (Alpha (SRGB l)) (Fixed a)) where
    toMisoString :: Color (Alpha (SRGB l)) (Fixed a) -> MisoString
    toMisoString (ColorSRGBA ((255 *) -> r) ((255 *) -> g) ((255 *) -> b) a) =
        fn' "rgb"
            $ [showFixed True r, showFixed True g, showFixed True b]
            <> ['/' : showFixed True a | a /= 1]

-- instance (Elevator e) => ToMisoString (Color OKLCH e) where
--     toMisoString :: Color OKLCH e -> MisoString
--     toMisoString (ColorOKLCH l c h) = fn "oklch" [toShowS l, toShowS c, toShowS h]

instance (HasResolution a) => ToMisoString (Color OKLCH (Fixed a)) where
    toMisoString :: Color OKLCH (Fixed a) -> MisoString
    toMisoString (ColorOKLCH l c h) = fn' "oklch" [showFixed True l, showFixed True c, showFixed True h]

-- instance (Elevator e) => ToMisoString (Color (Alpha OKLCH) e) where
--     toMisoString :: Color (Alpha OKLCH) e -> MisoString
--     toMisoString (ColorOKLCHA l c h a) =
--         fn "oklch"
--             $ [toShowS l, toShowS c, toShowS h]
--             <> if a == 1 then [] else [showChar '/', toShowS a]

instance (HasResolution a) => ToMisoString (Color (Alpha OKLCH) (Fixed a)) where
    toMisoString :: Color (Alpha OKLCH) (Fixed a) -> MisoString
    toMisoString (ColorOKLCHA l c h a) =
        fn' "oklch"
            $ [showFixed True l, showFixed True c, showFixed True h]
            <> ['/' : showFixed True a | a /= 1]

instance (ToMisoString c, Eq c) => ToMisoString (LightDark c) where
    toMisoString :: LightDark c -> MisoString
    toMisoString LightDark{..}
        | light == dark = toMisoString light
        | otherwise =
            "light-dark(" <> toMisoString light <> "," <> toMisoString dark <> ")"

toClayColor :: (Clay.Val (Color cs e)) => Color cs e -> Clay.Color
toClayColor = Clay.Other . Clay.value

rgbHex :: (ColorSpace cs i e) => Color cs e -> MisoString
rgbHex c = "#" <> channel r <> channel g <> channel b
  where
    ColorSRGB r g b = convert @_ @_ @_ @(SRGB 'NonLinear) c
    channel :: Double -> MisoString
    channel = toMisoString . fmap toUpper . flip showHex "" . round @_ @Word8 . (* 255)
