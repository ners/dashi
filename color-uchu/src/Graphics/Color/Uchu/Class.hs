module Graphics.Color.Uchu.Class where

import Graphics.Color.Uchu.Palette (Palette)

class Uchu c cs e where
    uchu :: Palette c cs e
