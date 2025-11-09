{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Button where

import Clay hiding (Background, Color, action, fullWidth, label, size, span_, var)
import Clay qualified hiding (Color, fullWidth)
import Control.Monad (when)
import Dashi.Components.Icon ()
import Dashi.Components.Spinner (Spinner (Spinner))
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style.Colour (LightDark, sameLightDark)
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util
import Data.Foldable (for_)
import Data.Functor ((<&>))
import Data.List qualified as List
import Data.Maybe (fromJust)
import Data.Semigroup (sconcat)
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Data.String (fromString)
import GHC.IsList (IsList (fromList))
import Graphics.Color.Model (Alpha, setAlpha)
import Graphics.Color.Space.OKLAB.LCH
import Miso hiding (view)
import Miso.Html.Element (button_, label_)
import Prelude

data Background = Background Appearance InputState
    deriving stock (Eq)

allBackgrounds :: Seq Background
allBackgrounds = Seq.fromList $ Background <$> [minBound .. maxBound] <*> [minBound .. maxBound]

instance Enum Background where
    toEnum = Seq.index allBackgrounds
    fromEnum = fromJust . flip Seq.elemIndexL allBackgrounds

instance Bounded Background where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Seq.length allBackgrounds

instance Token Background where
    tokenName (Background appearance state) =
        fromString . List.intercalate "-" $
            ["button-background", tokenName appearance, tokenName state]

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue (Background Default state) = sameLightDark . ColorOKLCHA 0.2422 0.0735 260.41 $ 0.05 * (fromIntegral . succ . fromEnum) state
    tokenValue (Background Subtle DefaultState) = flip setAlpha 0 <$> tokenValue (Background Default DefaultState)
    tokenValue (Background Subtle state) = tokenValue $ Background Default state
    tokenValue (Background appearance state) =
        tokenValue (Colour.Text appearance) <&> \(ColorOKLCHA l c h _) ->
            let l' = l - (fromIntegral . fromEnum $ state) * 0.1
             in ColorOKLCHA l' c h 1

data ButtonSize
    = DefaultSize
    | IconButton
    | CompactButton
    | FullWidthButton
    deriving stock (Eq, Bounded, Enum)

instance Token ButtonSize where
    tokenName DefaultSize = "default"
    tokenName IconButton = "icon"
    tokenName CompactButton = "compact"
    tokenName FullWidthButton = "full-width"
    defaultToken = Just DefaultSize

data Button model action = Button
    { size :: ButtonSize
    , appearance :: Appearance
    , label :: [View model action]
    }

instance Widget (Button model action) model action where
    widget' attrs Button{..} =
        button_ (tokenAttr size : tokenAttr appearance : attrs <> [unselectable_ | isBusy]) $
            label_ [] label : [widget Spinner | isBusy]
      where
        isBusy = hasAriaBusy attrs

    style = do
        ":root" ? tokenDecl @Background
        sconcat [Clay.button, input # ("type" @= "submit"), ".button"] ? do
            pressable
            userSelect none
            position relative
            boxShadow . fromList $
                [bsInset . bsColor (colorToken Colour.Border) $ shadowWithBlur nil nil (var "border-width" [])]
            byToken Subtle & ("box-shadow" -: "none")
            borderRadiusAll' Small
            paddingYX' XSmall Medium
            byToken IconButton & do
                paddingYX' XSmall XSmall
                Clay.label ? Clay.span # ".mdi" ? transform none
            byToken CompactButton & do
                paddingYX (em 0.125) (token $ Space Medium)
                Clay.span ? transform (translateY nil)
            byToken FullWidthButton & do
                fullWidth
                Clay.label ? do
                    fullWidth
                    justifyContent spaceEvenly
            fontWeight $ weight 550
            color' $ Colour.Text Subtle
            backgroundColor' $ Background Default DefaultState
            transition "background" (sec 0.2) easeOut 0
            Clay.label ? do
                display inlineFlex
                alignItems baseline
                justifyContent center
                textAlign center
                gap' XSmall
                lineHeight $ unitless 1.6
                Clay.pointerEvents none
                Clay.span # ":not(.mdi)" ? transform (translateY . em $ -0.1)
                Clay.span # ".mdi" ? transform (translateY . em $ 0.05)
            ".mdi" ? fontSize' Large
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
            for_ @[] allTokens \appearance ->
                byToken appearance & do
                    when (elem @[] appearance [Primary, Success, Warning, Danger, Discovery]) $ color' Colour.InverseText
                    backgroundColor' $ Background appearance DefaultState
                    sconcat [ariaBusy False, Clay.not disabled] & do
                        hover & backgroundColor' (Background appearance HoveredState)
                        active & backgroundColor' (Background appearance ActiveState)
