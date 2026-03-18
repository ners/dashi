module Graphics.Color.Uchu.Extended.Color where

import Graphics.Color.Adaptation.VonKries qualified as Color
import Graphics.Color.Space

data Extended cs e = Extended
    { _1 :: Color cs e
    , _2 :: Color cs e
    , _3 :: Color cs e
    , _4 :: Color cs e
    , _5 :: Color cs e
    , _6 :: Color cs e
    , _7 :: Color cs e
    , _8 :: Color cs e
    , _9 :: Color cs e
    }

convert
    :: (ColorSpace cs' i' e', ColorSpace cs i e)
    => Extended cs' e'
    -> Extended cs e
convert Extended{..} =
    Extended
        { _1 = Color.convert _1
        , _2 = Color.convert _2
        , _3 = Color.convert _3
        , _4 = Color.convert _4
        , _5 = Color.convert _5
        , _6 = Color.convert _6
        , _7 = Color.convert _7
        , _8 = Color.convert _8
        , _9 = Color.convert _9
        }
