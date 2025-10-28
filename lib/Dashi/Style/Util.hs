{-# LANGUAGE AllowAmbiguousTypes #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Util where

import Clay hiding (cast, fullWidth, var)
import Clay.Property ()
import Clay.Render (renderRefinement)
import Clay.Selector (Fix (In), Path (Elem), Refinement (Refinement), SelectorF (SelectorF), refinementFromText)
import Clay.Stylesheet (App (Root), Rule (Nested), key, rule, runS)
import Dashi.Style.Tokens
import Dashi.Util
import Data.String (IsString)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Lazy qualified as LazyText
import Prelude

self :: Selector
self = ""

ariaBusy :: Bool -> Refinement
ariaBusy True = "aria-busy" @= "true"
ariaBusy False = Clay.not $ ariaBusy True

ariaRole :: Text -> Refinement
ariaRole = ("aria-role" @=)

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

varName :: (IsString s, Semigroup s) => s -> s
varName = ("--dashi-" <>)

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

focusable :: Css
focusable = ":focus-visible" & outline solid (var "outline-width" []) (token BorderFocused)

underlinedOnHover :: Css
underlinedOnHover = do
    hover & star ? textDecoration underline
    ":focus-visible" & star ? textDecoration underline

pressable :: Css
pressable = do
    cursor pointer
    focusable

color' :: Colour -> Css
color' = color . token

borderColor' :: Colour -> Css
borderColor' = borderColor . token

backgroundColor' :: (Token t, ValueType t ~ Color) => t -> Css
backgroundColor' = backgroundColor . token

paddingYX' :: SizeToken -> SizeToken -> Css
paddingYX' y x = paddingYX (token $ Space y) (token $ Space x)

paddingAll' :: SizeToken -> Css
paddingAll' = paddingAll . token . Space

marginAll' :: SizeToken -> Css
marginAll' = marginAll . token . Space

borderRadiusAll' :: SizeToken -> Css
borderRadiusAll' = borderRadiusAll . token . Radius

gap' :: SizeToken -> Css
gap' = ("gap" ~::) . token . Space

rowGap' :: SizeToken -> Css
rowGap' = ("row-gap" ~::) . token . Space

columnGap' :: SizeToken -> Css
columnGap' = ("column-gap" ~::) . token . Space

gridTemplateAreas :: [[Value]] -> Css
gridTemplateAreas areas = "grid-template-areas" ~: intercalate "\n    " ("" : (areaRow <$> areas))
  where
    areaRow :: [Value] -> Value
    areaRow [] = ""
    areaRow [x] = x
    areaRow xs = "'" <> intercalate " " xs <> "'"

fontSize' :: SizeToken -> Css
fontSize' = Clay.fontSize . token . FontSize

isOneOf :: [Refinement] -> Refinement
isOneOf refinements =
    refinementFromText . LazyText.toStrict $
        ":is(" <> LazyText.intercalate "," (concatMap renderRefinement refinements) <> ")"

isOneOf' :: (Token t) => [t] -> Refinement
isOneOf' = isOneOf . fmap byToken

isOneOfAll' :: forall t. (Token t) => Refinement
isOneOfAll' = isOneOf' $ allTokens @t

has :: Selector -> Refinement
has selector =
    refinementFromText . LazyText.toStrict $
        ":has(" <> renderSelector selector <> ")"
