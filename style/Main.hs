module Main where

import Dashi.Style (style)
import Dashi.Style.Util (renderStyle)
import Data.Text.IO.Utf8
import System.IO (IO)
import Prelude ()

main :: IO ()
main = putStrLn (renderStyle style)
