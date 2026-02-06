module Language where

import Dashi.Prelude
import Dashi.Util (fromText)
import Data.Bifunctor (Bifunctor (first))
import Data.Char (isAlphaNum)
import Data.Either.Extra (eitherToMaybe, maybeToEither)
import Data.List qualified as List
import Language.Fluent.Bundle (Bundle)
import Language.Fluent.Bundle qualified as Fluent
import Language.Fluent.Locale (Locale (Locale))
import Language.Fluent.Message qualified as Fluent
import Miso.JSON (FromJSON (parseJSON), Parser (Parser), ToJSON (toJSON))
import Miso.String qualified as MisoString

data Language
    = English
    | German
    | French
    | Italian
    deriving stock (Eq, Show, Bounded, Enum)

code :: Language -> MisoString
code English = "en"
code German = "de"
code French = "fr"
code Italian = "it"

fromCode :: MisoString -> Maybe Language
fromCode s = List.find ((s ==) . code) [minBound .. maxBound]

instance FromMisoString Language where
    fromMisoStringEither s =
        maybeToEither ("Unknown language code: " <> fromMisoString s)
            $ fromCode s

instance ToMisoString Language where
    toMisoString = code

instance FromJSVal Language where
    fromJSVal = fmap (eitherToMaybe . fromMisoStringEither =<<) . fromJSVal

instance ToJSVal Language where
    toJSVal = toJSVal . toMisoString

instance FromJSON Language where
    parseJSON = Parser . first toMisoString . fromMisoStringEither <=< parseJSON

instance ToJSON Language where
    toJSON = toJSON @MisoString . toMisoString

locale :: Language -> Locale
locale = Locale . fromMisoString . code

fromLocale :: Locale -> Maybe Language
fromLocale (Locale l) = do
    (s, _) <- List.uncons . MisoString.split (not . isAlphaNum) . toMisoString $ l
    eitherToMaybe . fromMisoStringEither $ s

class Translatable model where
    getBundle :: model -> Maybe Bundle

translate
    :: (Translatable model)
    => model
    -> MisoString
    -> Either String MisoString
translate model key = do
    bundle <- maybeToEither "No bundle" . getBundle $ model
    message <-
        maybeToEither "Failed to get message"
            . Fluent.getMessage bundle
            . fromMisoString
            $ key
    value <- maybeToEither "Failed to get value" . Fluent.getValue $ message
    fromText <$> Fluent.formatPattern bundle value

unsafeTranslate :: (Translatable model) => model -> MisoString -> MisoString
unsafeTranslate model key = either toMisoString id $ translate model key
