module Dashi.Util where

import Data.Char (toUpper)
import Data.String (IsString (fromString))
import Data.Text (Text)
import Data.Text qualified as Text
import Miso (Attribute (Styles), MisoString, fromMisoString, toMisoString)
import Prelude

fromText :: (IsString s) => Text -> s
fromText = fromString . Text.unpack

capitalise :: MisoString -> MisoString
capitalise s =
    case Text.uncons $ fromMisoString s of
        Nothing -> s
        Just (x, xs) -> toMisoString $ Text.cons (toUpper x) xs

emptyAttr_ :: Attribute action
emptyAttr_ = Styles mempty
