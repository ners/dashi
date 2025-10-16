module Dashi.Components.Button where

import Clay (label)
import Clay hiding (action, label, var)
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Aeson qualified as Aeson
import Data.List qualified as List
import Data.Maybe (isJust)
import Miso
import Miso.Html (button_, label_)
import Miso.Html.Property (aria_, class_)
import Prelude

data ButtonAppearance
    = PrimaryButton
    | SubtleButton
    | WarningButton
    | DangerButton
    | DiscoveryButton
    deriving stock (Eq, Bounded, Enum, Show)

instance Token ButtonAppearance where
    tokenName PrimaryButton = "primary"
    tokenName SubtleButton = "subtle"
    tokenName WarningButton = "warning"
    tokenName DangerButton = "danger"
    tokenName DiscoveryButton = "discovery"

buttonAppearance :: ButtonAppearance -> Attribute action
buttonAppearance = class_ . tokenName

data ComponentState
    = DisabledState
    | SelectedState
    | LoadingState
    deriving stock (Eq, Bounded, Enum)

data ComponentSpacing
    = DefaultSpacing
    | CompactSpacing
    deriving stock (Eq, Bounded, Enum)

data ComponentWidth
    = AutoWidth
    | FullWidth
    deriving stock (Eq, Bounded, Enum)

hasProperty :: MisoString -> Aeson.Value -> [Attribute action] -> Bool
hasProperty k v =
    isJust . List.find \case
        Property k' v' -> k' == k && v' == v
        _ -> False

hasAria :: MisoString -> MisoString -> [Attribute action] -> Bool
hasAria k = hasProperty ("aria-" <> k) . Aeson.String . fromMisoString

button :: [Attribute action] -> MisoString -> View model action
button attrs l =
    button_
        attrs
        (label_ [] [text l] : if (hasAria "busy" "true" attrs) then [Spinner.view] else [])

style :: Css
style = do
    (Clay.button <> ".button") ? do
        clickable
        position relative
        display inlineFlex
        alignItems baseline
        justifyContent center
        textAlign center
        verticalAlign middle
        border (px 1) solid (var "border-color" [])
        borderRadiusAll' Small
        paddingYX' XSmall Small
        fontWeight $ weight 500
        color' TextSubtle
        backgroundColor' $ BackgroundNeutral DefaultState
        transition "background" (sec 0.1) easeOut 0
        disabled & borderWidth (unitless 0)
        label ? Clay.pointerEvents none
        ariaBusy True & label ? opacity 0
        ".spinner" ? do
            position absolute
            left $ pct 50
            "transform" -: "translateX(-50%)"
            top . token $ Space XSmall
            display inlineBlock
            width $ em 1.4
            height $ em 1.4
        ariaBusy False & do
            hover & backgroundColor' (BackgroundNeutral HoveredState)
            active & backgroundColor' (BackgroundNeutral PressedState)
        byClass (tokenName PrimaryButton) & do
            borderWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundBrandBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundBrandBold HoveredState)
                active & backgroundColor' (BackgroundBrandBold PressedState)
        byClass (tokenName SubtleButton) & do
            borderWidth $ unitless 0
            backgroundColor transparent
            ariaBusy False & do
                hover & backgroundColor' (BackgroundNeutral HoveredState)
                active & backgroundColor' (BackgroundNeutral PressedState)
        byClass (tokenName WarningButton) & do
            borderWidth $ unitless 0
            backgroundColor' $ BackgroundWarningBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundWarningBold HoveredState)
                active & backgroundColor' (BackgroundWarningBold PressedState)
        byClass (tokenName DangerButton) & do
            borderWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundDangerBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundDangerBold HoveredState)
                active & backgroundColor' (BackgroundDangerBold PressedState)
        byClass (tokenName DiscoveryButton) & do
            borderWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundDiscoveryBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundDiscoveryBold HoveredState)
                active & backgroundColor' (BackgroundDiscoveryBold PressedState)
