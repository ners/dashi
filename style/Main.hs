module Main where

import Dashi.Style (style)
import Dashi.Style.Util (renderStyle)
import Data.Text.IO.Utf8 qualified as Text
import System.IO (IO)

main :: IO ()
main = Text.putStrLn (renderStyle style)
