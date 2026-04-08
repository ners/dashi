{-# LANGUAGE AllowAmbiguousTypes #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Util where

import Clay hiding (Color, cast, fullWidth, var)
import Clay qualified
import Clay.Property ()
import Clay.Render (renderRefinement)
import Clay.Selector
    ( Fix (In)
    , Path (Elem)
    , Refinement (Refinement)
    , SelectorF (SelectorF)
    , refinementFromText
    )
import Clay.Stylesheet (App (Root), Rule (Nested), key, rule, runS)
import Dashi.Style.Colour ()
import Dashi.Style.Tokens
import Dashi.Util
import Data.String (IsString (..))
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Lazy qualified as LazyText
import Prelude

renderStyle :: (IsString s) => Css -> s
renderStyle = fromString . LazyText.unpack . renderWith pretty []

self :: Selector
self = ""

ariaBusy :: Bool -> Refinement
ariaBusy True = "aria-busy" @= "true"
ariaBusy False = Clay.not $ ariaBusy True

ariaCurrent :: Bool -> Refinement
ariaCurrent True = "aria-current" @= "true"
ariaCurrent False = Clay.not $ ariaCurrent True

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
paddingYX y x = "padding" ~:: intercalate @Value " " [value y, value x]

marginYX :: Size a -> Size a -> Css
marginYX y x = "margin" ~:: intercalate @Value " " [value y, value x]

paddingAll :: Size a -> Css
paddingAll = ("padding" ~::)

borderRadiusAll :: Size a -> Css
borderRadiusAll = ("border-radius" ~::)

varName :: (IsString s, Semigroup s) => s -> s
varName = ("--dashi-" <>)

var' :: (Val v, Other v) => Text -> [v] -> v
var' name' defaults = other . fromText $ "var(" <> Text.intercalate "," parts <> ")"
  where
    parts = name' : (plain . unValue . value <$> defaults)

var :: (Val v, Other v) => Text -> [v] -> v
var = var' . varName

token :: (Token t, Val (ValueType t), Other (ValueType t)) => t -> ValueType t
token t = var (tokenName t) []

token' :: (Token t, Val (ValueType t), Other (ValueType t)) => t -> ValueType t
token' t = var' (tokenName t) []

colorToken :: (Token t) => t -> Clay.Color
colorToken t = var (tokenName t) []

colorToken' :: (Token t) => t -> Clay.Color
colorToken' t = var' (tokenName t) []

(~:) :: Key Text -> Value -> Css
k ~: v = key (cast k) v

(~::) :: (Val v) => Key Text -> v -> Css
k ~:: v = k ~: value v

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

underlinedOnHover :: Css
underlinedOnHover = do
    hover & star ? textDecoration underline
    focusVisible & star ? textDecoration underline

focusVisible :: Refinement
focusVisible = ":focus-visible"

color' :: (Token t) => t -> Css
color' = color . colorToken

borderColor' :: (Token t) => t -> Css
borderColor' = borderColor . colorToken

backgroundColor' :: (Token t) => t -> Css
backgroundColor' = backgroundColor . colorToken

paddingYX' :: SizeToken -> SizeToken -> Css
paddingYX' y x = paddingYX (token $ Space y) (token $ Space x)

paddingAll' :: SizeToken -> Css
paddingAll' = paddingAll . token . Space

marginYX' :: SizeToken -> SizeToken -> Css
marginYX' y x = marginYX (token $ Space y) (token $ Space x)

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
    areaRow xs = "'" <> intercalate @Value " " xs <> "'"

fontSize' :: SizeToken -> Css
fontSize' = Clay.fontSize . token . FontSize

isOneOf :: [Refinement] -> Refinement
isOneOf refinements =
    refinementFromText . LazyText.toStrict $
        ":is("
            <> LazyText.intercalate "," (concatMap renderRefinement refinements)
            <> ")"

isOneOf' :: (Token t) => [t] -> Refinement
isOneOf' = isOneOf . fmap byToken

isOneOfAll' :: forall t. (Token t) => Refinement
isOneOfAll' = isOneOf' $ allTokens @t

has :: Selector -> Refinement
has selector =
    refinementFromText . LazyText.toStrict $
        ":has(" <> renderSelector selector <> ")"
