module Dashi.Util where

import Data.String (IsString (fromString))
import Data.Text (Text)
import Data.Text qualified as Text
import Prelude

fromText :: (IsString s) => Text -> s
fromText = fromString . Text.unpack
