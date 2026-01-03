{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Util where

import Clay (Refinement)
import Clay.Selector (Refinement (Refinement))
import Control.Lens.Combinators
import Control.Lens.Operators
import Data.Char (isUpper, toLower, toUpper)
import Data.Fixed (Fixed, HasResolution)
import Data.String (IsString (fromString))
import Data.Text (Text)
import Data.Text qualified as Text
import GHC.Float (FFFormat (..), formatRealFloat)
import Miso (Attribute (Styles), MisoString, fromMisoString, toMisoString)
import Miso.String (FromMisoString, ToMisoString)
import Numeric (fromRat)
import Prelude
#ifdef WASM
import Miso.String (JSString)
import Miso.String qualified as JSString
#endif

ishow :: (Show a, IsString s) => a -> s
ishow = fromString . show

fromText :: (IsString s) => Text -> s
fromText = fromString . Text.unpack

misoShow :: (Show a) => a -> MisoString
misoShow = toMisoString . Text.show

formatFloat :: (RealFloat a) => a -> String
formatFloat v
    | v == 0 = "0"
    | abs v < 1e-5 || abs v > 1e10 = formatRealFloat FFExponent Nothing v
    | v - fromIntegral @Int (floor v) == 0 = formatRealFloat FFFixed (Just 0) v
    | otherwise = formatRealFloat FFGeneric Nothing v

instance (HasResolution k) => ToMisoString (Fixed k) where
    toMisoString = toMisoString . formatFloat @Double . realToFrac

instance ToMisoString Rational where
    toMisoString = toMisoString . formatFloat @Double . fromRat

#ifdef WASM
instance Cons JSString JSString Char Char where
    _Cons = prism' (uncurry JSString.cons) JSString.uncons
#endif

capitalise :: (Cons s s Char Char) => s -> s
capitalise = _head %~ toUpper

uncapitalise :: (Cons s s Char Char) => s -> s
uncapitalise = _head %~ toLower

misoStringIso :: (FromMisoString a, ToMisoString a) => Iso' MisoString a
misoStringIso = iso fromMisoString toMisoString

pascalWords :: Iso' Text [Text]
pascalWords = iso (breakAll isUpper) (mconcat . fmap capitalise)

breakAll :: (Char -> Bool) -> Text -> [Text]
breakAll f t
    | Just (c, cs) <- Text.uncons r = ls <> (breakAll f cs & _head %~ Text.cons c)
    | otherwise = ls
  where
    (l, r) = Text.break f t
    ls = [l | not $ Text.null l]

unpascal :: MisoString -> MisoString
unpascal = misoStringIso %~ Text.unwords . fmap uncapitalise . breakAll isUpper

emptyAttr_ :: Attribute action
emptyAttr_ = Styles mempty

emptyRefinement :: Refinement
emptyRefinement = Refinement mempty

cyclePred :: (Eq a, Enum a, Bounded a) => a -> a
cyclePred x = if x == minBound then maxBound else pred x

cycleSucc :: (Eq a, Enum a, Bounded a) => a -> a
cycleSucc x = if x == maxBound then minBound else succ x
