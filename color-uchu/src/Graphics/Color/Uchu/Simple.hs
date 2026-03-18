{-# LANGUAGE UndecidableInstances #-}

module Graphics.Color.Uchu.Simple
    ( Uchu (..)
    , Palette (..)
    , Simple (..)
    )
where

import Graphics.Color.Space
import Graphics.Color.Space.OKLAB.LCH (OKLCH)
import Graphics.Color.Uchu.Class
import Graphics.Color.Uchu.Palette
import Graphics.Color.Uchu.Palette qualified as Palette
import Graphics.Color.Uchu.Simple.Color
import Graphics.Color.Uchu.Simple.Color qualified as Simple
import Graphics.Color.Uchu.Simple.OKLCH ()
import Prelude

instance {-# OVERLAPS #-} (ColorSpace cs i e) => Uchu Simple cs e where
    uchu = Palette.convert @Simple @OKLCH @Double Simple.convert uchu
