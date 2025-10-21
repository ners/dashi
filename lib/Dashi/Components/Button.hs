module Dashi.Components.Button where

import Clay hiding (action, var)
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Components.Util
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso
import Miso.Html (button_, label_)
import Miso.Html.Property (class_)
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

button :: [Attribute action] -> [View model action] -> View model action
button attrs elems = button_ attrs $ label_ [] elems : [Spinner.view | isAriaBusy attrs]

style :: Css
style = do
    (Clay.button <> (input # "type='submit'") <> ".button") ? do
        clickable
        position relative
        border (var "border-width" []) solid (token BorderInput)
        borderRadiusAll' Small
        paddingYX' XSmall Small
        fontWeight $ weight 500
        color' TextSubtle
        backgroundColor' $ BackgroundNeutral DefaultState
        transition "background" (sec 0.1) easeOut 0
        disabled & borderWidth (unitless 0)
        label ? do
            display inlineFlex
            alignItems baseline
            justifyContent center
            textAlign center
            verticalAlign middle
            gap' XSmall
            Clay.pointerEvents none
            important $ textDecoration none
        ".mdi" ? fontSize (em 1)
        ".spinner" ? do
            opacity 1
            position absolute
            left $ pct 50
            "transform" -: "translateX(-50%)"
            top . token $ Space XSmall
            display inlineBlock
            width $ em 1.4
            height $ em 1.4
        ariaBusy True & label ? opacity 0
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
