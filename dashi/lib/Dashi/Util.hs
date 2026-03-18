{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashi.Util where

import Clay (Refinement)
import Clay.Selector (Refinement (Refinement))
import Dashi.Prelude
import Data.Char (isUpper, toLower, toUpper)
import Data.Text (Text)
import Data.Text qualified as Text
import GHC.Float (FFFormat (..), formatRealFloat)
import Miso.String qualified as MisoString
import Numeric (fromRat)

fromText :: (IsString s) => Text -> s
fromText = fromString . Text.unpack

formatFloat :: (RealFloat a, IsString s) => a -> s
formatFloat v
    | v == 0 = "0"
    | abs v < 1e-5 || abs v > 1e10 =
        fromString $ formatRealFloat FFExponent Nothing v
    | v - fromIntegral @Int (floor v) == 0 =
        fromString $ formatRealFloat FFFixed (Just 0) v
    | otherwise = fromString $ formatRealFloat FFGeneric Nothing v

instance (HasResolution k) => ToMisoString (Fixed k) where
    toMisoString = formatFloat @Double . realToFrac

instance ToMisoString Rational where
    toMisoString = formatFloat @Double . fromRat

#ifndef VANILLA
instance Cons MisoString MisoString Char Char where
    _Cons = prism' (uncurry MisoString.cons) MisoString.uncons
#endif

capitalise :: (Cons s s Char Char) => s -> s
capitalise = _head %~ toUpper

uncapitalise :: (Cons s s Char Char) => s -> s
uncapitalise = _head %~ toLower

misoStringIso :: (FromMisoString a, ToMisoString a) => Iso' MisoString a
misoStringIso = iso fromMisoString toMisoString

pascalWords :: Iso' MisoString [MisoString]
pascalWords = iso (breakAll isUpper) (mconcat . fmap capitalise)

breakAll :: (Char -> Bool) -> MisoString -> [MisoString]
breakAll f t
    | Just (c, cs) <- MisoString.uncons r =
        ls <> case breakAll f cs of
            x : xs -> MisoString.cons c x : xs
            [] -> [MisoString.singleton c]
    | otherwise = ls
  where
    (l, r) = MisoString.break f t
    ls = [l | not $ MisoString.null l]

unpascal :: MisoString -> MisoString
unpascal = MisoString.unwords . fmap uncapitalise . view pascalWords

emptyView_ :: View model action
emptyView_ = VText Nothing mempty

emptyAttr_ :: Attribute action
emptyAttr_ = Styles mempty

emptyRefinement :: Refinement
emptyRefinement = Refinement mempty

cyclePred :: (Eq a, Enum a, Bounded a) => a -> a
cyclePred x = if x == minBound then maxBound else pred x

cycleSucc :: (Eq a, Enum a, Bounded a) => a -> a
cycleSucc x = if x == maxBound then minBound else succ x
