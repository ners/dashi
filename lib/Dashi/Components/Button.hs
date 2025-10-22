module Dashi.Components.Button where

import Clay hiding (action, fullWidth, label, size, span_, var)
import Clay qualified hiding (fullWidth)
import Control.Monad (unless, when)
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Spinner qualified as Spinner
import Dashi.Components.Util
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Foldable (forM_)
import Data.List qualified as List
import Data.Maybe (catMaybes, fromJust)
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Data.String (fromString)
import Miso
import Miso.Html (button_, label_, span_)
import Web.Font.MDI (MDI)
import Prelude

data ButtonBackground = ButtonBackground Appearance InputState
    deriving stock (Eq, Ord)

allButtonBackgrounds :: Seq ButtonBackground
allButtonBackgrounds = Seq.fromList $ ButtonBackground <$> [minBound .. maxBound] <*> [minBound .. maxBound]

instance Enum ButtonBackground where
    toEnum = Seq.index allButtonBackgrounds
    fromEnum = fromJust . flip Seq.elemIndexL allButtonBackgrounds

instance Bounded ButtonBackground where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Seq.length allButtonBackgrounds

instance Token ButtonBackground where
    tokenName (ButtonBackground appearance state) =
        fromString . List.intercalate "-" $
            ["button", tokenName appearance, tokenName state]

instance ValueToken ButtonBackground where
    type ValueType ButtonBackground = Color
    tokenValue (ButtonBackground Default st) =
        rgba 9 30 66 $ case st of
            DefaultState -> 0.04
            HoveredState -> 0.08
            PressedState -> 0.14
    tokenValue (ButtonBackground Primary DefaultState) = parse "#0052CC"
    tokenValue (ButtonBackground Primary HoveredState) = parse "#0065FF"
    tokenValue (ButtonBackground Primary PressedState) = parse "#0747A6"
    tokenValue (ButtonBackground Success _) = tokenValue $ Icon Success -- TODO find better colour
    tokenValue (ButtonBackground Subtle DefaultState) = transparent
    tokenValue (ButtonBackground Subtle st) = tokenValue $ ButtonBackground Default st
    tokenValue (ButtonBackground Warning DefaultState) = parse "#FBC828"
    tokenValue (ButtonBackground Warning HoveredState) = parse "#FCA700"
    tokenValue (ButtonBackground Warning PressedState) = parse "#F68909"
    tokenValue (ButtonBackground Danger DefaultState) = parse "#C9372C"
    tokenValue (ButtonBackground Danger HoveredState) = parse "#AE2E24"
    tokenValue (ButtonBackground Danger PressedState) = parse "#5D1F1A"
    tokenValue (ButtonBackground Discovery DefaultState) = parse "#964AC0"
    tokenValue (ButtonBackground Discovery HoveredState) = parse "#803FA5"
    tokenValue (ButtonBackground Discovery PressedState) = parse "#48245D"

data ButtonSize
    = DefaultSize
    | CompactButton
    | FullWidthButton
    deriving stock (Eq, Bounded, Enum)

instance Token ButtonSize where
    tokenName DefaultSize = "default"
    tokenName CompactButton = "compact"
    tokenName FullWidthButton = "full-width"
    defaultToken = Just DefaultSize

data Button = Button
    { size :: ButtonSize
    , appearance :: Appearance
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
    ":root" ? tokenDecl @ButtonBackground
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
        color' $ Text Subtle
        backgroundColor' $ ButtonBackground Default DefaultState
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
        forM_ allTokens \appearance ->
            byToken appearance & do
                unless (appearance == Default) . outlineWidth $ unitless 0
                when (appearance `elem` [Primary, Success, Danger, Discovery]) $ color' InverseText
                backgroundColor' $ ButtonBackground appearance DefaultState
                ariaBusy False & do
                    hover & backgroundColor' (ButtonBackground appearance HoveredState)
                    active & backgroundColor' (ButtonBackground appearance PressedState)
