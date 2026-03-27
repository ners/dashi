{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Tokens where

import Clay hiding (Color, FontSize, fontSize)
import Dashi.Prelude
import Dashi.Util (emptyAttr_, emptyRefinement)
import GHC.IsList (IsList (..))
import Miso.Html.Property (class_)

class Token t where
    tokenName :: (IsString s, Semigroup s) => t -> s
    defaultToken :: Maybe t
    defaultToken = Nothing
    tokenAttr :: t -> Attribute action
    default tokenAttr :: (Eq t) => t -> Attribute action
    tokenAttr t
        | Just t == defaultToken = emptyAttr_
        | otherwise = class_ $ tokenName t
    byToken :: t -> Refinement
    default byToken :: (Eq t) => t -> Refinement
    byToken t
        | Just t == defaultToken = emptyRefinement
        | otherwise = byClass $ tokenName t
    allTokens :: (IsList l, Item l ~ t) => l
    default allTokens :: (IsList l, Item l ~ t, Bounded t, Enum t) => l
    allTokens = fromList [minBound .. maxBound]

byTokens :: (Token t) => (t -> Css) -> Css
byTokens f = for_ @[] allTokens \t -> byToken t Clay.& f t

nonDefaultTokenName :: (Token t, Eq t, IsString s, Semigroup s) => t -> Maybe s
nonDefaultTokenName t
    | Just t == defaultToken = Nothing
    | otherwise = Just $ tokenName t

class (Token t) => ValueToken t where
    type ValueType t
    tokenValue :: t -> ValueType t

data SizeToken
    = XSmall
    | Small
    | Medium
    | Large
    | XLarge
    deriving stock (Eq, Ord, Bounded, Enum, Show)

instance Token SizeToken where
    tokenName XSmall = "xs"
    tokenName Small = "s"
    tokenName Medium = "m"
    tokenName Large = "l"
    tokenName XLarge = "xl"

newtype Space = Space {spaceSize :: SizeToken}
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token Space where
    tokenName = fromString . ("space-" <>) . tokenName . spaceSize

spaceEm :: SizeToken -> Number
spaceEm = (0.4 *) . (1.75 ^) . fromEnum

instance ValueToken Space where
    type ValueType Space = Size LengthUnit
    tokenValue = em . spaceEm . spaceSize

newtype Radius = Radius {radiusSize :: SizeToken}
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token Radius where
    tokenName = fromString . ("radius-" <>) . tokenName . radiusSize

instance ValueToken Radius where
    type ValueType Radius = Size LengthUnit
    tokenValue = em . (0.1 *) . (2 ^) . fromEnum . radiusSize

newtype FontSize = FontSize {fontSize :: SizeToken}
    deriving newtype (Eq, Ord, Bounded, Enum)

instance Token FontSize where
    tokenName = fromString . ("font-size-" <>) . tokenName . fontSize

instance ValueToken FontSize where
    type ValueType FontSize = Size Percentage
    tokenValue FontSize{..} = pct $ case fontSize of
        XSmall -> 60
        Small -> 85
        Medium -> 100
        Large -> 125
        XLarge -> 200

data Appearance
    = Default
    | Subtle
    | Primary
    | Success
    | Warning
    | Danger
    | Discovery
    deriving stock (Eq, Bounded, Enum)

instance Token Appearance where
    tokenName Default = "default"
    tokenName Subtle = "subtle"
    tokenName Primary = "primary"
    tokenName Success = "success"
    tokenName Warning = "warning"
    tokenName Danger = "danger"
    tokenName Discovery = "discovery"
    defaultToken = Just Default

data InputState
    = DefaultState
    | HoveredState
    | ActiveState
    deriving stock (Eq, Bounded, Enum)

instance Token InputState where
    tokenName DefaultState = "default"
    tokenName HoveredState = "hovered"
    tokenName ActiveState = "active"
    defaultToken = Just DefaultState
    byToken DefaultState = emptyRefinement
    byToken HoveredState = hover
    byToken ActiveState = active

data BorderWidth = BorderWidth
    deriving stock (Eq, Bounded, Enum)

instance Token BorderWidth where
    tokenName BorderWidth = "border-width"

instance ValueToken BorderWidth where
    type ValueType BorderWidth = Size LengthUnit
    tokenValue BorderWidth = Clay.rem 0.0625
