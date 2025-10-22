{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Tokens where

import Clay
import Control.Category ((>>>))
import Dashi.Util (emptyAttr_)
import Data.Maybe (fromJust)
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Data.String (IsString (fromString))
import Miso (Attribute)
import Miso.Html.Property (class_)
import Prelude hiding (rem)

class Token t where
    tokenName :: (IsString s) => t -> s
    tokenAttr :: t -> Attribute action
    tokenAttr = class_ . tokenName
    allTokens :: [t]
    default allTokens :: (Bounded t, Enum t) => [t]
    allTokens = [minBound .. maxBound]

class (Token t) => ValueToken t where
    type ValueType t
    tokenValue :: t -> ValueType t

data SizeToken
    = XSmall
    | Small
    | Medium
    | Large
    | XLarge
    deriving stock (Eq, Ord, Bounded, Enum)

instance Show SizeToken where
    show XSmall = "xs"
    show Small = "s"
    show Medium = "m"
    show Large = "l"
    show XLarge = "xl"

newtype Space = Space {spaceSize :: SizeToken}
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token Space where
    tokenName = fromString . ("space-" <>) . show . spaceSize

spaceEm :: SizeToken -> Number
spaceEm = (0.4 *) . (1.75 ^) . fromEnum

instance ValueToken Space where
    type ValueType Space = Size LengthUnit
    tokenValue = em . spaceEm . spaceSize

newtype Radius = Radius {radiusSize :: SizeToken}
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token Radius where
    tokenName = fromString . ("radius-" <>) . show . radiusSize

instance ValueToken Radius where
    type ValueType Radius = Size LengthUnit
    tokenValue = em . (0.1 *) . (2 ^) . fromEnum . radiusSize

data ElementState
    = DefaultState
    | HoveredState
    | PressedState
    deriving stock (Eq, Ord, Bounded, Enum)

data Colour
    = Text
    | TextBrand
    | TextDanger
    | TextDisabled
    | TextDiscovery
    | TextInformation
    | TextInverse
    | TextSubtle
    | TextSubtlest
    | TextSuccess
    | TextWarning
    | TextWarningInverse
    | IconBrand
    | IconWarning
    | IconDanger
    | IconSuccess
    | IconDiscovery
    | Border
    | BorderInput
    | BackgroundInput ElementState
    | BackgroundDisabled
    | BackgroundInformation
    | BackgroundWarning
    | BackgroundSuccess
    | BackgroundError
    | BackgroundDiscovery
    | BackgroundBrandBold ElementState
    | BackgroundDangerBold ElementState
    | BackgroundDiscoveryBold ElementState
    | BackgroundNeutral ElementState
    | BackgroundWarningBold ElementState
    deriving stock (Eq, Ord)

allColours :: Seq Colour
allColours =
    Seq.fromList $
        [ Text
        , TextBrand
        , TextDanger
        , TextDisabled
        , TextDiscovery
        , TextInformation
        , TextInverse
        , TextSubtle
        , TextSubtlest
        , TextSuccess
        , TextWarning
        , TextWarningInverse
        , IconBrand
        , IconWarning
        , IconDanger
        , IconSuccess
        , IconDiscovery
        , Border
        , BorderInput
        , BackgroundDisabled
        , BackgroundInformation
        , BackgroundWarning
        , BackgroundSuccess
        , BackgroundError
        , BackgroundDiscovery
        ]
            <> (BackgroundBrandBold <$> [minBound .. maxBound])
            <> (BackgroundDangerBold <$> [minBound .. maxBound])
            <> (BackgroundDiscoveryBold <$> [minBound .. maxBound])
            <> (BackgroundNeutral <$> [minBound .. maxBound])
            <> (BackgroundWarningBold <$> [minBound .. maxBound])
            <> (BackgroundInput <$> [minBound .. maxBound])

instance Enum Colour where
    toEnum :: Int -> Colour
    toEnum = Seq.index allColours
    fromEnum :: Colour -> Int
    fromEnum = fromJust . flip Seq.elemIndexL allColours

instance Bounded Colour where
    minBound :: Colour
    minBound = toEnum 0
    maxBound :: Colour
    maxBound = toEnum . pred $ Seq.length allColours

instance Token Colour where
    tokenName Text = "text"
    tokenName TextBrand = "text-brand"
    tokenName TextDanger = "text-danger"
    tokenName TextDisabled = "text-disabled"
    tokenName TextDiscovery = "text-discovery"
    tokenName TextInformation = "text-information"
    tokenName TextInverse = "text-inverse"
    tokenName TextSubtle = "text-subtle"
    tokenName TextSubtlest = "text-subtlest"
    tokenName TextSuccess = "text-success"
    tokenName TextWarning = "text-warning"
    tokenName TextWarningInverse = "text-warning-inverse"
    tokenName IconBrand = "icon-brand"
    tokenName IconWarning = "icon-warning"
    tokenName IconDanger = "icon-danger"
    tokenName IconSuccess = "icon-success"
    tokenName IconDiscovery = "icon-discovery"
    tokenName Border = "border-color"
    tokenName BorderInput = "border-input-color"
    tokenName BackgroundDisabled = "background-disabled"
    tokenName BackgroundInformation = "background-information"
    tokenName BackgroundSuccess = "background-success"
    tokenName BackgroundWarning = "background-warning"
    tokenName BackgroundError = "background-error"
    tokenName BackgroundDiscovery = "background-discovery"
    tokenName (BackgroundBrandBold DefaultState) = "background-brand-bold"
    tokenName (BackgroundBrandBold HoveredState) = "background-brand-bold-hovered"
    tokenName (BackgroundBrandBold PressedState) = "background-brand-bold-pressed"
    tokenName (BackgroundDangerBold DefaultState) = "background-danger-bold"
    tokenName (BackgroundDangerBold HoveredState) = "background-danger-bold-hovered"
    tokenName (BackgroundDangerBold PressedState) = "background-danger-bold-pressed"
    tokenName (BackgroundDiscoveryBold DefaultState) = "background-discovery-bold"
    tokenName (BackgroundDiscoveryBold HoveredState) = "background-discovery-bold-hovered"
    tokenName (BackgroundDiscoveryBold PressedState) = "background-discovery-bold-pressed"
    tokenName (BackgroundNeutral DefaultState) = "background-neutral"
    tokenName (BackgroundNeutral HoveredState) = "background-neutral-hovered"
    tokenName (BackgroundNeutral PressedState) = "background-neutral-pressed"
    tokenName (BackgroundWarningBold DefaultState) = "background-warning-bold"
    tokenName (BackgroundWarningBold HoveredState) = "background-warning-bold-hovered"
    tokenName (BackgroundWarningBold PressedState) = "background-warning-bold-pressed"
    tokenName (BackgroundInput DefaultState) = "input-background"
    tokenName (BackgroundInput HoveredState) = "input-hover-background"
    tokenName (BackgroundInput PressedState) = "input-pressed-background"

instance ValueToken Colour where
    type ValueType Colour = Color
    tokenValue Text = parse "#292A2E"
    tokenValue TextBrand = parse "#1868DB"
    tokenValue TextDanger = parse "#AE2E24"
    tokenValue TextDiscovery = parse "#803FA5"
    tokenValue TextInformation = parse "#1558BC"
    tokenValue TextSuccess = parse "#292A2E"
    tokenValue TextWarning = parse "#9E4C00"
    tokenValue TextWarningInverse = parse "#292A2E"
    tokenValue TextInverse = parse "#FFF"
    tokenValue TextSubtle = parse "#505258"
    tokenValue TextSubtlest = parse "#6B6E76"
    tokenValue TextDisabled = rgba 8 15 33 0.3
    tokenValue IconBrand = parse "#1868DB"
    tokenValue IconWarning = parse "#E06C00"
    tokenValue IconDanger = parse "#C9372C"
    tokenValue IconSuccess = parse "#6A9A23"
    tokenValue IconDiscovery = parse "#AF59E1"
    tokenValue Border = parse "#0B120E24"
    tokenValue BorderInput = parse "#8C8F97"
    tokenValue BackgroundDisabled = rgba 23 23 23 0.03
    tokenValue BackgroundInformation = parse "#E9F2FE"
    tokenValue BackgroundWarning = parse "#FFF5DB"
    tokenValue BackgroundSuccess = parse "#EFFFD6"
    tokenValue BackgroundError = parse "#FFECEB"
    tokenValue BackgroundDiscovery = parse "#F8EEFE"
    tokenValue (BackgroundNeutral st) = rgba 9 30 66 $ case st of
        DefaultState -> 0.04
        HoveredState -> 0.08
        PressedState -> 0.14
    tokenValue (BackgroundBrandBold DefaultState) = parse "#0052CC"
    tokenValue (BackgroundBrandBold HoveredState) = parse "#0065FF"
    tokenValue (BackgroundBrandBold PressedState) = parse "#0747A6"
    tokenValue (BackgroundWarningBold DefaultState) = parse "#FBC828"
    tokenValue (BackgroundWarningBold HoveredState) = parse "#FCA700"
    tokenValue (BackgroundWarningBold PressedState) = parse "#F68909"
    tokenValue (BackgroundDangerBold DefaultState) = parse "#C9372C"
    tokenValue (BackgroundDangerBold HoveredState) = parse "#AE2E24"
    tokenValue (BackgroundDangerBold PressedState) = parse "#5D1F1A"
    tokenValue (BackgroundDiscoveryBold DefaultState) = parse "#964AC0"
    tokenValue (BackgroundDiscoveryBold HoveredState) = parse "#803FA5"
    tokenValue (BackgroundDiscoveryBold PressedState) = parse "#48245D"
    tokenValue (BackgroundInput DefaultState) = parse "#FFF"
    tokenValue (BackgroundInput HoveredState) = parse "#F8F8F8"
    tokenValue (BackgroundInput PressedState) = parse "#FFF"
