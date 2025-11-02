module Language where

import Control.Monad ((<=<))
import Dashi.Util (fromText)
import Data.List qualified as List
import Data.String (IsString)
import Language.Fluent.Bundle (Bundle)
import Language.Fluent.Bundle qualified as Fluent
import Language.Fluent.Locale (Locale (Locale))
import Language.Fluent.Message qualified as Fluent
import Miso
import Prelude

data Language
    = English
    | German
    | French
    | Italian
    deriving stock (Eq, Show, Bounded, Enum)

code :: (IsString s) => Language -> s
code English = "en"
code German = "de"
code French = "fr"
code Italian = "it"

fromCode :: MisoString -> Maybe Language
fromCode str = List.find (\lang -> code lang == str) [minBound .. maxBound]

locale :: Language -> Locale
locale = Locale . code

class Translatable model where
    getBundle :: model -> Bundle

translate :: (Translatable model) => model -> MisoString -> Either String MisoString
translate model =
    fmap fromText
        . Fluent.formatPattern bundle
        <=< maybe (Left "Failed to get value") Right . Fluent.getValue
        <=< maybe (Left "Failed to get message") Right . Fluent.getMessage bundle . fromMisoString
  where
    bundle = getBundle model
