{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Button where

import Clay hiding
    ( Background
    , Color
    , action
    , fullWidth
    , label
    , size
    , span_
    , var
    )
import Clay qualified hiding (Color, fullWidth)
import Dashi.Components.Icon ()
import Dashi.Components.Spinner (Spinner (Spinner))
import Dashi.Components.Util
import Dashi.Prelude hiding (none, transform, (#), (&))
import Dashi.Style.Border (BorderColour (BorderColour))
import Dashi.Style.Colour (LightDark (..), sameLightDark)
import Dashi.Style.Pseudo (pressable)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Text
    ( TextColour (TextColour)
    )
import Dashi.Style.Tokens
import Dashi.Style.Uchu (Uchu (..), UchuAlpha (..))
import Dashi.Style.Uchu qualified as Uchu
import Dashi.Style.Util
import Data.List qualified as List
import Data.Vector.Strict qualified as Vector
import GHC.IsList (IsList (fromList))
import Miso.Html.Element (button_, label_)
import Miso.Html.Event qualified as Html

newtype Foreground = Foreground Appearance
    deriving newtype (Bounded, Enum, Eq)

instance Token Foreground where
    tokenName (Foreground appearance) =
        fromString
            . List.intercalate "-"
            . catMaybes
            $ [Just "button-foreground", nonDefaultTokenName appearance]

instance ValueToken Foreground where
    type ValueType Foreground = LightDark (UchuAlpha Micro)
    tokenValue (Foreground Default) = tokenValue $ TextColour Default
    tokenValue (Foreground Subtle) = tokenValue $ TextColour Subtle
    tokenValue (Foreground _) = flip UchuAlpha 1 <$> sameLightDark Yang

data Background = Background Appearance InputState
    deriving stock (Eq)

allBackgrounds :: Vector Background
allBackgrounds = Background <$> [minBound .. maxBound] <*> [minBound .. maxBound]

instance Enum Background where
    toEnum = (Vector.!) allBackgrounds
    fromEnum = fromJust . flip Vector.findIndex allBackgrounds . (==)

instance Bounded Background where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Vector.length allBackgrounds

instance Token Background where
    tokenName (Background appearance state) =
        fromString
            . List.intercalate "-"
            . catMaybes
            $ [ Just "button-background"
              , nonDefaultTokenName appearance
              , nonDefaultTokenName state
              ]

instance ValueToken Background where
    type ValueType Background = LightDark (UchuAlpha Milli)
    tokenValue (Background Default state) =
        flip UchuAlpha alpha <$> LightDark Yin2 Yin8
      where
        alpha = 0.25 * (fromIntegral . succ . fromEnum) state
    tokenValue (Background Subtle DefaultState) = Uchu.setAlpha 0 <$> tokenValue (Background Default DefaultState)
    tokenValue (Background Subtle state) = tokenValue $ Background Default state
    tokenValue (Background Primary DefaultState) = flip UchuAlpha 1 <$> sameLightDark Blue4
    tokenValue (Background Primary HoveredState) = flip UchuAlpha 1 <$> sameLightDark Blue5
    tokenValue (Background Primary ActiveState) = flip UchuAlpha 1 <$> sameLightDark Blue6
    tokenValue (Background Success DefaultState) = flip UchuAlpha 1 <$> sameLightDark Green4
    tokenValue (Background Success HoveredState) = flip UchuAlpha 1 <$> sameLightDark Green5
    tokenValue (Background Success ActiveState) = flip UchuAlpha 1 <$> sameLightDark Green6
    tokenValue (Background Warning DefaultState) = flip UchuAlpha 1 <$> sameLightDark Orange4
    tokenValue (Background Warning HoveredState) = flip UchuAlpha 1 <$> sameLightDark Orange5
    tokenValue (Background Warning ActiveState) = flip UchuAlpha 1 <$> sameLightDark Orange6
    tokenValue (Background Danger DefaultState) = flip UchuAlpha 1 <$> sameLightDark Red4
    tokenValue (Background Danger HoveredState) = flip UchuAlpha 1 <$> sameLightDark Red5
    tokenValue (Background Danger ActiveState) = flip UchuAlpha 1 <$> sameLightDark Red6
    tokenValue (Background Discovery DefaultState) = flip UchuAlpha 1 <$> sameLightDark Purple4
    tokenValue (Background Discovery HoveredState) = flip UchuAlpha 1 <$> sameLightDark Purple5
    tokenValue (Background Discovery ActiveState) = flip UchuAlpha 1 <$> sameLightDark Purple6

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
    , onClick :: Maybe action
    }

appearanceStyle :: Appearance -> Css
appearanceStyle appearance = do
    when (appearance == Subtle) $ "box-shadow" -: "none"
    color' $ Foreground appearance
    backgroundColor' $ Background appearance DefaultState
    sconcat [ariaBusy False, Clay.not disabled] & do
        hover & backgroundColor' (Background appearance HoveredState)
        active & backgroundColor' (Background appearance ActiveState)

sizeStyle :: ButtonSize -> Css
sizeStyle DefaultSize = pure ()
sizeStyle IconButton = do
    paddingYX' XSmall XSmall
    Clay.label ? Clay.span # ".mdi" ? transform none
sizeStyle CompactButton = do
    paddingYX (em 0.125) (token $ Space Medium)
    Clay.span ? transform (translateY nil)
sizeStyle FullWidthButton = do
    fullWidth
    Clay.label ? do
        fullWidth
        justifyContent spaceEvenly

instance Widget (Button model action) model action where
    widget' attrs Button{..} =
        button_
            ( tokenAttr size
                : tokenAttr appearance
                : attrs
                    <> [unselectable_ | isBusy]
                    <> maybeToList (Html.onClickPrevent <$> onClick)
            )
            $ label_ [] label
            : [widget Spinner | isBusy]
      where
        isBusy = hasAriaBusy attrs

    style = do
        ":root" ? do
            tokenDecl @Foreground
            tokenDecl @Background
        sconcat [Clay.button, input # ("type" @= "submit"), ".button"] ? do
            pressable
            userSelect none
            position relative
            boxShadow
                . fromList
                $ [ bsInset
                        . bsColor (colorToken BorderColour)
                        $ shadowWithBlur nil nil (var "border-width" [])
                  ]
            color' $ TextColour Subtle
            borderRadiusAll' Small
            paddingYX' XSmall Medium
            fontWeight $ weight 550
            backgroundColor' $ Background Default DefaultState
            transition "background" (sec 0.15) easeOut 0
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
            byTokens sizeStyle
            byTokens appearanceStyle
