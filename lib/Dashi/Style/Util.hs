{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Util where

import Clay hiding (cast, fullWidth, var)
import Clay.Property ()
import Clay.Selector (Fix (In), Path (Elem), Refinement (Refinement), SelectorF (SelectorF))
import Clay.Stylesheet (App (Root), Rule (Nested), key, rule, runS)
import Dashi.Style.Tokens
import Data.String (IsString (fromString))
import Data.Text (Text)
import Data.Text qualified as Text
import Prelude

fromText :: (IsString s) => Text -> s
fromText = fromString . Text.unpack

self :: Selector
self = ""

ariaBusy :: Bool -> Refinement
ariaBusy True = "@aria-busy='true'"
ariaBusy False = Clay.not $ ariaBusy True

fullWidth :: Css
fullWidth = width $ pct 100

fullHeight :: Css
fullHeight = height $ pct 100

fullSize :: Css
fullSize = do
    fullWidth
    fullHeight

marginAll :: Size a -> Css
marginAll = ("margin" ~::)

paddingYX :: Size a -> Size a -> Css
paddingYX y x = "padding" ~:: intercalate " " [value y, value x]

paddingAll :: Size a -> Css
paddingAll = ("padding" ~::)

borderRadiusAll :: Size a -> Css
borderRadiusAll = ("border-radius" ~::)

varName :: (IsString s) => Text -> s
varName = fromText . ("--dashi-" <>)

var :: (Val v, Other v) => Text -> [v] -> v
var name' defaults = other . fromText $ "var(" <> Text.intercalate "," parts <> ")"
  where
    parts = (varName name') : (plain . unValue . value <$> defaults)

token :: (Token t, Val (ValueType t), Other (ValueType t)) => t -> ValueType t
token t = var (tokenName t) []

(~:) :: Key Text -> Value -> Css
k ~: v = key (cast k) v

(~::) :: (Val v) => Key Text -> v -> Css
k ~:: v = k ~: (value v)

cast :: Key a -> Key b
cast (Key k) = Key k

rawSelector :: Text -> Selector
rawSelector = In . SelectorF (Refinement []) . Elem

rawQuery :: Text -> Css -> Css
rawQuery t = rule . Nested (Root $ rawSelector t) . runS

fontList :: [Value] -> Value
fontList = intercalate ","

instance Font Value

fontFamily' :: Value -> Css
fontFamily' = fontFamily [] . pure . other

clickable :: Css
clickable = cursor pointer

color' :: Colour -> Css
color' = color . token

backgroundColor' :: Colour -> Css
backgroundColor' = backgroundColor . token

paddingYX' :: SizeToken -> SizeToken -> Css
paddingYX' y x = paddingYX (token $ Space y) (token $ Space x)

borderRadiusAll' :: SizeToken -> Css
borderRadiusAll' = borderRadiusAll . token . Radius
