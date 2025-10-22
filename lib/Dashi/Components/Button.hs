module Dashi.Components.Button where

import Clay hiding (action, fullWidth, label, size, span_, var)
import Clay qualified hiding (fullWidth)
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Components.Util
import Dashi.Style.Tokens
import Dashi.Style.Util
import Dashi.Util (emptyAttr_)
import Data.Maybe (catMaybes)
import Miso
import Miso.Html (button_, label_, span_)
import Miso.Html.Property (class_)
import Web.Font.MDI (MDI)
import Prelude

data ButtonSize
    = DefaultSize
    | CompactButton
    | FullWidthButton
    deriving stock (Eq, Bounded, Enum)

instance Token ButtonSize where
    tokenName DefaultSize = "default"
    tokenName CompactButton = "compact"
    tokenName FullWidthButton = "full-width"
    tokenAttr DefaultSize = emptyAttr_
    tokenAttr t = class_ $ tokenName t

data ButtonAppearance
    = DefaultButton
    | PrimaryButton
    | SubtleButton
    | WarningButton
    | DangerButton
    | DiscoveryButton
    deriving stock (Eq, Bounded, Enum)

instance Token ButtonAppearance where
    tokenName DefaultButton = "default"
    tokenName PrimaryButton = "primary"
    tokenName SubtleButton = "subtle"
    tokenName WarningButton = "warning"
    tokenName DangerButton = "danger"
    tokenName DiscoveryButton = "discovery"
    tokenAttr DefaultButton = emptyAttr_
    tokenAttr t = class_ $ tokenName t

data Button = Button
    { size :: ButtonSize
    , appearance :: ButtonAppearance
    , label :: MisoString
    , leftIcon :: Maybe MDI
    , rightIcon :: Maybe MDI
    }

view :: [Attribute action] -> Button -> View model action
view attrs Button{..} =
    button_ (tokenAttr size : tokenAttr appearance : attrs) $
        labelElem : [Spinner.view | isAriaBusy attrs]
  where
    labelElem =
        label_ [] . catMaybes $
            [ Icon.view [] <$> leftIcon
            , pure $ span_ [] [text label]
            , Icon.view [] <$> rightIcon
            ]

style :: Css
style = do
    (Clay.button <> (input # "type='submit'") <> ".button") ? do
        cursor pointer
        position relative
        outline solid (var "border-width" []) (token Border)
        marginAll $ px 1
        borderRadiusAll' Small
        paddingYX' XSmall Medium
        byToken CompactButton & do
            paddingYX (em 0.125) (token $ Space Medium)
            Clay.span ? transform (translateY $ unitless 0)
        byToken FullWidthButton & do
            fullWidth
            Clay.label ? do
                fullWidth
                justifyContent spaceEvenly
        fontWeight $ weight 550
        color' TextSubtle
        backgroundColor' $ BackgroundNeutral DefaultState
        transition "background" (sec 0.1) easeOut 0
        disabled & outlineWidth (unitless 0)
        Clay.label ? do
            display inlineFlex
            alignItems baseline
            justifyContent center
            textAlign center
            gap' XSmall
            Clay.pointerEvents none
            Clay.span ? transform (translateY . px $ -1)
        ".mdi" ? fontSize (pct 110)
        ".spinner" ? do
            opacity 1
            position absolute
            left $ pct 50
            "transform" -: "translateX(-50%)"
            top . token $ Space XSmall
            display inlineBlock
            width $ em 1.4
            height $ em 1.4
        ariaBusy True & Clay.label ? opacity 0
        ariaBusy False & do
            hover & backgroundColor' (BackgroundNeutral HoveredState)
            active & backgroundColor' (BackgroundNeutral PressedState)
        byToken PrimaryButton & do
            outlineWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundBrandBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundBrandBold HoveredState)
                active & backgroundColor' (BackgroundBrandBold PressedState)
        byToken SubtleButton & do
            outlineWidth $ unitless 0
            backgroundColor transparent
            ariaBusy False & do
                hover & backgroundColor' (BackgroundNeutral HoveredState)
                active & backgroundColor' (BackgroundNeutral PressedState)
        byToken WarningButton & do
            outlineWidth $ unitless 0
            backgroundColor' $ BackgroundWarningBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundWarningBold HoveredState)
                active & backgroundColor' (BackgroundWarningBold PressedState)
        byToken DangerButton & do
            outlineWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundDangerBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundDangerBold HoveredState)
                active & backgroundColor' (BackgroundDangerBold PressedState)
        byToken DiscoveryButton & do
            outlineWidth $ unitless 0
            color' TextInverse
            backgroundColor' $ BackgroundDiscoveryBold DefaultState
            ariaBusy False & do
                hover & backgroundColor' (BackgroundDiscoveryBold HoveredState)
                active & backgroundColor' (BackgroundDiscoveryBold PressedState)
