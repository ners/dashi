module Language where

import Dashi.Prelude
import Dashi.Util (fromText)
import Data.Either.Extra (maybeToEither)
import Data.List qualified as List
import Language.Fluent.Bundle (Bundle)
import Language.Fluent.Bundle qualified as Fluent
import Language.Fluent.Locale (Locale (Locale))
import Language.Fluent.Message qualified as Fluent

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

fromLocale :: Locale -> Maybe Language
fromLocale (Locale l) = fromCode $ toMisoString l

locale :: Language -> Locale
locale = Locale . code

class Translatable model where
    getBundle :: model -> Maybe Bundle

translate :: (Translatable model) => model -> MisoString -> Either String MisoString
translate model key = do
    bundle <- maybeToEither "No bundle" . getBundle $ model
    message <- maybeToEither "Failed to get message" . Fluent.getMessage bundle . fromMisoString $ key
    value <- maybeToEither "Failed to get value" . Fluent.getValue $ message
    fromText <$> Fluent.formatPattern bundle value

unsafeTranslate :: (Translatable model) => model -> MisoString -> MisoString
unsafeTranslate model key = either toMisoString id $ translate model key
