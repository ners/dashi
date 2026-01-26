module Dashi.Prelude
    ( module Dashi.Prelude
    , module Control.Lens.Combinators
    , module Control.Lens.Operators
    , module Dashi.Components.Widget
    , module Data.Foldable
    , module Data.Maybe
    , module Data.Semigroup
    , module Data.String
    , module GHC.Generics
    , module Miso.String
    , module Miso.Types
    , module Miso.Prelude
    )
where

import Control.Lens.Combinators
import Control.Lens.Operators
import Dashi.Components.Widget
import Data.Foldable (for_)
import Data.Generics.Labels ()
import Data.Maybe
import Data.Semigroup (Semigroup (sconcat))
import Data.String (IsString (fromString))
import GHC.Generics (Generic)
import Miso.Prelude hiding (at, set, view, (#))
import Miso.String (FromMisoString, MisoString, ToMisoString, fromMisoString, fromMisoStringEither, toMisoString)
import Miso.Types (Attribute, View, text, textRaw)

ishow :: (Show a, IsString s) => a -> s
ishow = fromString . show
