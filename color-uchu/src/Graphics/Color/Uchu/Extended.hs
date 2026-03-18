{-# LANGUAGE UndecidableInstances #-}

module Graphics.Color.Uchu.Extended
    ( Uchu (..)
    , Palette (..)
    , Extended (..)
    )
where

import Graphics.Color.Space
import Graphics.Color.Space.OKLAB.LCH (OKLCH)
import Graphics.Color.Uchu.Class
import Graphics.Color.Uchu.Extended.Color
import Graphics.Color.Uchu.Extended.Color qualified as Extended
import Graphics.Color.Uchu.Extended.OKLCH ()
import Graphics.Color.Uchu.Palette
import Graphics.Color.Uchu.Palette qualified as Palette
import Prelude

instance {-# OVERLAPS #-} (ColorSpace cs i e) => Uchu Extended cs e where
    uchu = Palette.convert @Extended @OKLCH @Double Extended.convert uchu
