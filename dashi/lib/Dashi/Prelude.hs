module Dashi.Prelude
    ( module Dashi.Prelude
    , module Control.Applicative
    , module Control.Lens.Combinators
    , module Control.Lens.Operators
    , module Control.Monad
    , module Dashi.Components.Widget
    , module Data.Bool
    , module Data.Fixed
    , module Data.Foldable
    , module Data.Maybe
    , module Data.Semigroup
    , module Data.String
    , module Data.Vector.Strict
    , module GHC.Generics
    , module Miso.FFI.QQ
    , module Miso.Prelude
    , module Miso.String
    , module Miso.Types
    )
where

import Control.Applicative
import Control.Lens.Combinators
import Control.Lens.Operators
import Control.Monad
import Dashi.Components.Widget
import Data.Bool
import Data.Fixed
import Data.Foldable (for_)
import Data.Generics.Labels ()
import Data.Maybe
import Data.Semigroup (Semigroup (sconcat))
import Data.String (IsString (fromString))
import Data.Vector.Strict (Vector)
import GHC.Generics (Generic)
import Miso.FFI.QQ (js)
import Miso.Prelude hiding (at, set, view, (#))
import Miso.String
    ( FromMisoString
    , MisoString
    , ToMisoString
    , fromMisoString
    , fromMisoStringEither
    , toMisoString
    )
import Miso.Types (Attribute, View, text, textRaw)

ishow :: (Show a, IsString s) => a -> s
ishow = fromString . show
