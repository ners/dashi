module Graphics.Color.Uchu.Simple.OKLCH where

import Graphics.Color.Space
import Graphics.Color.Space.OKLAB.LCH
import Graphics.Color.Uchu.Class
import Graphics.Color.Uchu.Palette
import Graphics.Color.Uchu.Simple.Color
import Prelude

instance (Fractional num) => Uchu Simple OKLCH num where
    uchu =
        Palette
            { blue =
                Simple
                    { base = ColorOKLCH 0.6239 0.181 258.33
                    , dark = ColorOKLCH 0.4348 0.17 260.2
                    , light = ColorOKLCH 0.8966 0.046 260.67
                    }
            , gray =
                Simple
                    { base = ColorOKLCH 0.8468 0.002 197.12
                    , dark = ColorOKLCH 0.6312 0.004 219.55
                    , light = ColorOKLCH 0.9557 0.003 286.35
                    }
            , green =
                Simple
                    { base = ColorOKLCH 0.7933 0.179 145.62
                    , dark = ColorOKLCH 0.5883 0.158 145.05
                    , light = ColorOKLCH 0.9396 0.05 148.74
                    }
            , pink =
                Simple
                    { base = ColorOKLCH 0.8543 0.09 354.1
                    , dark = ColorOKLCH 0.6411 0.084 353.91
                    , light = ColorOKLCH 0.958 0.023 354.27
                    }
            , purple =
                Simple
                    { base = ColorOKLCH 0.5847 0.181 302.06
                    , dark = ColorOKLCH 0.3946 0.164 298.29
                    , light = ColorOKLCH 0.891 0.046 305.24
                    }
            , orange =
                Simple
                    { base = ColorOKLCH 0.7875 0.14163582809066333 54.32911089172009
                    , dark = ColorOKLCH 0.5828 0.128 52.2
                    , light = ColorOKLCH 0.9383 0.037 56.93
                    }
            , red =
                Simple
                    { base = ColorOKLCH 0.6273 0.209 12.37
                    , dark = ColorOKLCH 0.458 0.177 17.7
                    , light = ColorOKLCH 0.8898 0.052 3.28
                    }
            , yellow =
                Simple
                    { base = ColorOKLCH 0.9092 0.125 92.56
                    , dark = ColorOKLCH 0.6914 0.109 91.04
                    , light = ColorOKLCH 0.9705 0.039 91.2
                    }
            }

lightYin :: (Fractional num) => Color OKLCH num
lightYin = ColorOKLCH 0.9187 0.003 264.54

yin :: (Fractional num) => Color OKLCH num
yin = ColorOKLCH 0.1438 0.007 256.88

yang :: (Fractional num) => Color OKLCH num
yang = ColorOKLCH 0.994 0 0
