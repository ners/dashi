{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Style.Tokens where

import Clay
import Dashi.Util (emptyAttr_, emptyRefinement)
import Data.Maybe (fromJust)
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Data.String (IsString (fromString))
import Miso (Attribute)
import Miso.Html.Property (class_)
import Prelude hiding (rem)

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

data Appearance
    = Default
    | Primary
    | Subtle
    | Success
    | Warning
    | Danger
    | Discovery
    deriving stock (Eq, Ord, Bounded, Enum)

instance Token Appearance where
    tokenName Default = "default"
    tokenName Primary = "primary"
    tokenName Subtle = "subtle"
    tokenName Success = "success"
    tokenName Warning = "warning"
    tokenName Danger = "danger"
    tokenName Discovery = "discovery"
    defaultToken = Just Default

data InputState
    = DefaultState
    | HoveredState
    | PressedState
    deriving stock (Eq, Ord, Bounded, Enum)

instance Token InputState where
    tokenName DefaultState = "default"
    tokenName HoveredState = "hovered"
    tokenName PressedState = "pressed"
    defaultToken = Just DefaultState
    byToken DefaultState = emptyRefinement
    byToken HoveredState = hover
    byToken PressedState = active

data Colour
    = Text Appearance
    | InverseText
    | DisabledText
    | Background Appearance
    | DisabledBackground
    | Icon Appearance
    | Border
    | InputBorder
    | BorderFocused
    | InputBorderDanger
    deriving stock (Eq, Ord)

allColours :: Seq Colour
allColours =
    mconcat . fmap Seq.fromList $
        [ Text <$> [minBound .. maxBound]
        , pure InverseText
        , pure DisabledText
        , Background <$> [minBound .. maxBound]
        , pure DisabledBackground
        , Icon <$> [minBound .. maxBound]
        , pure Border
        , pure InputBorder
        , pure BorderFocused
        , pure InputBorderDanger
        ]

instance Enum Colour where
    toEnum = Seq.index allColours
    fromEnum = fromJust . flip Seq.elemIndexL allColours

instance Bounded Colour where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Seq.length allColours

instance Token Colour where
    tokenName (Text appearance) = "text-" <> tokenName appearance
    tokenName InverseText = "text-inverse"
    tokenName DisabledText = "text-disabled"
    tokenName (Background appearance) = "background-" <> tokenName appearance
    tokenName DisabledBackground = "background-disabled"
    tokenName (Icon appearance) = "icon-" <> tokenName appearance
    tokenName Border = "border"
    tokenName InputBorder = "input-border"
    tokenName BorderFocused = "input-border-focused"
    tokenName InputBorderDanger = "input-border-danger"

instance ValueToken Colour where
    type ValueType Colour = Color
    tokenValue (Text Default) = parse "#292A2E"
    tokenValue (Text Primary) = parse "#1868DB"
    tokenValue (Text Subtle) = parse "#505258"
    tokenValue (Text Success) = parse "#292A2E"
    tokenValue (Text Warning) = parse "#9E4C00"
    tokenValue (Text Danger) = parse "#AE2E24"
    tokenValue (Text Discovery) = parse "#803FA5"
    tokenValue DisabledText = rgba 8 15 33 0.3
    tokenValue (Background Default) = parse "#E9F2FE"
    tokenValue (Background Subtle) = parse "#E9F2FE"
    tokenValue (Background Primary) = tokenValue $ Background Default
    tokenValue (Background Warning) = parse "#FFF5DB"
    tokenValue (Background Success) = parse "#EFFFD6"
    tokenValue (Background Danger) = parse "#FFECEB"
    tokenValue (Background Discovery) = parse "#F8EEFE"
    tokenValue DisabledBackground = rgba 23 23 23 0.03
    tokenValue InverseText = parse "#FFF"
    tokenValue (Icon Default) = tokenValue $ Text Default
    tokenValue (Icon Primary) = tokenValue $ Text Primary
    tokenValue (Icon Subtle) = tokenValue $ Text Subtle
    tokenValue (Icon Success) = parse "#6A9A23"
    tokenValue (Icon Warning) = parse "#E06C00"
    tokenValue (Icon Danger) = parse "#C9372C"
    tokenValue (Icon Discovery) = parse "#AF59E1"
    tokenValue Border = parse "#0B120E24"
    tokenValue InputBorder = parse "#8C8F97"
    tokenValue BorderFocused = parse "#4688EC"
    tokenValue InputBorderDanger = parse "#E2483D"
