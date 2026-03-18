module Graphics.Color.Uchu.Extended.OKLCH where

import Graphics.Color.Space.OKLAB.LCH
import Graphics.Color.Uchu.Class
import Graphics.Color.Uchu.Extended.Color
import Graphics.Color.Uchu.Palette
import Prelude

instance (Fractional num) => Uchu Extended OKLCH num where
    uchu =
        Palette
            { blue =
                Extended
                    { _1 = ColorOKLCH 0.8966 0.046 260.67
                    , _2 = ColorOKLCH 0.8017 0.091 258.88
                    , _3 = ColorOKLCH 0.7094 0.136 258.06
                    , _4 = ColorOKLCH 0.6239 0.181 258.33
                    , _5 = ColorOKLCH 0.5487 0.222 260.33
                    , _6 = ColorOKLCH 0.5115 0.204 260.17
                    , _7 = ColorOKLCH 0.4736 0.185 259.89
                    , _8 = ColorOKLCH 0.4348 0.17 260.2
                    , _9 = ColorOKLCH 0.3953 0.15 259.87
                    }
            , gray =
                Extended
                    { _1 = ColorOKLCH 0.9557 0.003 286.35
                    , _2 = ColorOKLCH 0.9204 0.002 197.12
                    , _3 = ColorOKLCH 0.8828 0.003 286.34
                    , _4 = ColorOKLCH 0.8468 0.002 197.12
                    , _5 = ColorOKLCH 0.8073 0.002 247.84
                    , _6 = ColorOKLCH 0.7503 0.002 247.85
                    , _7 = ColorOKLCH 0.6901 0.003 286.32
                    , _8 = ColorOKLCH 0.6312 0.004 219.55
                    , _9 = ColorOKLCH 0.5682 0.004 247.89
                    }
            , green =
                Extended
                    { _1 = ColorOKLCH 0.9396 0.05 148.74
                    , _2 = ColorOKLCH 0.8877 0.096 147.71
                    , _3 = ColorOKLCH 0.8374 0.139 146.57
                    , _4 = ColorOKLCH 0.7933 0.179 145.62
                    , _5 = ColorOKLCH 0.7523 0.209 144.64
                    , _6 = ColorOKLCH 0.7003 0.194 144.71
                    , _7 = ColorOKLCH 0.6424 0.175 144.92
                    , _8 = ColorOKLCH 0.5883 0.158 145.05
                    , _9 = ColorOKLCH 0.5277 0.138 145.41
                    }
            , pink =
                Extended
                    { _1 = ColorOKLCH 0.958 0.023 354.27
                    , _2 = ColorOKLCH 0.9214 0.046 352.31
                    , _3 = ColorOKLCH 0.889 0.066 354.39
                    , _4 = ColorOKLCH 0.8543 0.09 354.1
                    , _5 = ColorOKLCH 0.8223 0.112 355.33
                    , _6 = ColorOKLCH 0.7637 0.101 355.37
                    , _7 = ColorOKLCH 0.7023 0.092 354.96
                    , _8 = ColorOKLCH 0.6411 0.084 353.91
                    , _9 = ColorOKLCH 0.5768 0.074 353.14
                    }
            , purple =
                Extended
                    { _1 = ColorOKLCH 0.891 0.046 305.24
                    , _2 = ColorOKLCH 0.7868 0.091 305
                    , _3 = ColorOKLCH 0.685 0.136 303.78
                    , _4 = ColorOKLCH 0.5847 0.181 302.06
                    , _5 = ColorOKLCH 0.4939 0.215 298.31
                    , _6 = ColorOKLCH 0.4611 0.198 298.4
                    , _7 = ColorOKLCH 0.4277 0.181 298.49
                    , _8 = ColorOKLCH 0.3946 0.164 298.29
                    , _9 = ColorOKLCH 0.3601 0.145 298.35
                    }
            , orange =
                Extended
                    { _1 = ColorOKLCH 0.9383 0.037 56.93
                    , _2 = ColorOKLCH 0.8837 0.07258208750520016 55.80328658240742
                    , _3 = ColorOKLCH 0.8356 0.10753627570574478 56.492594564236946
                    , _4 = ColorOKLCH 0.7875 0.14163582809066333 54.32911089172009
                    , _5 = ColorOKLCH 0.7461 0.171 51.56
                    , _6 = ColorOKLCH 0.6933 0.157 52.18
                    , _7 = ColorOKLCH 0.638 0.142 52.1
                    , _8 = ColorOKLCH 0.5828 0.128 52.2
                    , _9 = ColorOKLCH 0.5249 0.113 51.98
                    }
            , red =
                Extended
                    { _1 = ColorOKLCH 0.8898 0.052 3.28
                    , _2 = ColorOKLCH 0.7878 0.109 4.54
                    , _3 = ColorOKLCH 0.6986 0.162 7.82
                    , _4 = ColorOKLCH 0.6273 0.209 12.37
                    , _5 = ColorOKLCH 0.5863 0.231 19.6
                    , _6 = ColorOKLCH 0.5441 0.214 19.06
                    , _7 = ColorOKLCH 0.4995 0.195 18.34
                    , _8 = ColorOKLCH 0.458 0.177 17.7
                    , _9 = ColorOKLCH 0.4117 0.157 16.58
                    }
            , yellow =
                Extended
                    { _1 = ColorOKLCH 0.9705 0.039 91.2
                    , _2 = ColorOKLCH 0.95 0.07 92.39
                    , _3 = ColorOKLCH 0.9276 0.098 92.58
                    , _4 = ColorOKLCH 0.9092 0.125 92.56
                    , _5 = ColorOKLCH 0.89 0.146 91.5
                    , _6 = ColorOKLCH 0.8239 0.133 91.5
                    , _7 = ColorOKLCH 0.7584 0.122 92.21
                    , _8 = ColorOKLCH 0.6914 0.109 91.04
                    , _9 = ColorOKLCH 0.6229 0.097 91.9
                    }
            }

yin :: (Fractional num) => Extended OKLCH num
yin =
    Extended
        { _1 = ColorOKLCH 0.9187 0.003 264.54
        , _2 = ColorOKLCH 0.8461 0.004 286.31
        , _3 = ColorOKLCH 0.7689 0.004 247.87
        , _4 = ColorOKLCH 0.6917 0.004 247.88
        , _5 = ColorOKLCH 0.6101 0.005 271.34
        , _6 = ColorOKLCH 0.5279 0.005 271.32
        , _7 = ColorOKLCH 0.4387 0.005 271.3
        , _8 = ColorOKLCH 0.3502 0.005 236.66
        , _9 = ColorOKLCH 0.2511 0.006 258.36
        }
