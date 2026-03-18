module Graphics.Color.Uchu.Simple.Color where

import Graphics.Color.Adaptation.VonKries qualified as Color
import Graphics.Color.Space

data Simple cs e = Simple
    { light :: Color cs e
    , base :: Color cs e
    , dark :: Color cs e
    }

convert
    :: (ColorSpace cs' i' e', ColorSpace cs i e)
    => Simple cs' e'
    -> Simple cs e
convert Simple{..} =
    Simple
        { light = Color.convert light
        , base = Color.convert base
        , dark = Color.convert dark
        }
