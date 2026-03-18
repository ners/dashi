{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}

module Main where

import Data.Fixed
import Graphics.Color.Space
import Graphics.Color.Space.OKLAB.LCH (OKLCH, pattern ColorOKLCH)
import Graphics.Color.Uchu
import Text.Pretty.Simple (pPrint)
import Text.Printf (printf)
import Prelude

instance {-# OVERLAPPING #-} (HasResolution a) => Show (Color OKLCH (Fixed a)) where
    show (ColorOKLCH l c h) =
        unwords
            [ "ColorOKLCH"
            , showFixed True l
            , showFixed True c
            , showFixed True h
            ]

instance {-# OVERLAPPING #-} Show (Color (SRGB l) Double) where
    show (ColorRGB r g b) =
        mconcat
            [ "\""
            , "#"
            , component r
            , component g
            , component b
            , "\""
            ]
      where
        component :: Double -> String
        component = printf "%02X" . round @_ @Word8 . (* 255)

deriving stock instance (Show (Color cs e)) => Show (Extended cs e)

deriving stock instance (Show (Color cs e)) => Show (Simple cs e)

deriving stock instance
    (Show (c cs e), Show (Color cs e))
    => Show (Palette c cs e)

main :: IO ()
main = do
    pPrint $ uchu @Simple @OKLCH @Nano
    pPrint $ uchu @Extended @OKLCH @Nano
    pPrint $ uchu @Simple @(SRGB 'NonLinear) @Double
    pPrint $ uchu @Extended @(SRGB 'NonLinear) @Double
