module UserPrefs where

import Control.Exception (SomeException, try)
import Control.Monad.Extra (eitherM)
import Dashi.Prelude hiding (get, set)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Colour qualified as Colour.Scheme
import Language (Language (..))

data UserPrefs = UserPrefs
    { colourScheme :: Colour.Scheme
    , language :: Language
    }
    deriving stock (Eq, Generic)

dummy :: UserPrefs
dummy = UserPrefs{colourScheme = minBound, language = minBound}

initial :: IO UserPrefs
initial = do
    colourScheme <-
        [js| return window.matchMedia("(prefers-color-scheme: dark)").matches |]
            <&> (^. Colour.Scheme.isDark)
    language <- [js| return navigator.language || navigator.userLanguage || "en" |]
    pure UserPrefs{..}

get :: IO UserPrefs
get = eitherM (const initial) pure $ try @SomeException do
    Just (fromMisoStringEither -> Right colourScheme) <- getLocalStorage "colour-scheme"
    Just (fromMisoStringEither -> Right language) <- getLocalStorage "language"
    pure UserPrefs{..}

set :: UserPrefs -> IO ()
set UserPrefs{..} = do
    consoleLog "UserPrefs.set"
    setLocalStorage "colour-scheme" $ toMisoString colourScheme
    setLocalStorage "language" $ toMisoString language

modify :: (UserPrefs -> UserPrefs) -> IO ()
modify f = set . f =<< get
