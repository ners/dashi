{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.ProgressBar where

import Clay hiding
    ( Background
    , Color
    , Value
    , action
    , fullWidth
    , max
    , size
    , value
    , var
    )
import Dashi.Prelude hiding (max, (&))
import Dashi.Style.Colour hiding (Background)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util
    ( backgroundColor'
    , borderRadiusAll'
    , fullWidth
    , var
    , (~:)
    )
import Data.List qualified as List
import Miso.Html.Element (progress_)
import Miso.Html.Property (max_, value_)

data Background = Background
    deriving stock (Eq, Bounded, Enum)

instance Token Background where
    tokenName Background = "progress-background-color"

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Milli)
    tokenValue Background = tokenValue (Text Default) <&> flip setAlpha 0.075

newtype Progress = Progress Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Progress where
    tokenName (Progress appearance) =
        fromString
            . List.intercalate "-"
            . catMaybes
            $ [ Just "progress"
              , Just "color"
              , nonDefaultTokenName appearance
              ]

instance ValueToken Progress where
    type ValueType Progress = LightDark (Color (Alpha OKLCH) Milli)
    tokenValue (Progress Default) = tokenValue BorderFocused
    tokenValue (Progress Primary) = tokenValue BorderFocused
    tokenValue (Progress appearance) = tokenValue (Text appearance)

data Value
    = Determinate {value :: Int, max :: Int}
    | Indeterminate

data ProgressBar = ProgressBar
    { value :: Value
    , appearance :: Appearance
    , size :: SizeToken
    }

instance Widget ProgressBar model action where
    widget' attrs ProgressBar{..} =
        progress_ (tokenAttr size : valueAttrs <> attrs) []
      where
        valueAttrs =
            case value of
                Determinate{..} -> [value_ $ toMisoString value, max_ $ toMisoString max]
                Indeterminate -> [textProp "indeterminate" ""]
    style = do
        ":root" ? do
            tokenDecl @Background
            tokenDecl @Progress
        progress ? do
            display block
            fullWidth
            backgroundColor' Background
            byTokens $ height . tokenValue . Space
            borderRadiusAll' Large
            "::-webkit-progress-bar" & do
                borderRadiusAll' Large
                background transparent
            "::-webkit-progress-value" & do
                borderRadiusAll' Large
                backgroundColor' $ Progress Default
            "::-moz-progress-bar" & do
                borderRadiusAll' Large
                backgroundColor' $ Progress Default
            indeterminate & do
                "::-webkit-progress-value" & background transparent
                "::-moz-progress-bar" & background transparent
                "background"
                    ~: mconcat
                        [ var (tokenName Background) []
                        , " "
                        , mconcat
                            [ "linear-gradient(to right, "
                            , var (tokenName $ Progress Default) []
                            , " 30%, transparent 30%)"
                            ]
                        , " "
                        , "top left / 150% 150% no-repeat"
                        ]
                animation
                    "progress-indeterminate"
                    (sec 2)
                    easeInOut
                    (sec 0)
                    infinite
                    normal
                    forwards

        keyframes
            "progress-indeterminate"
            [ (0, backgroundPosition $ positioned (pct 200) nil)
            , (100, backgroundPosition $ positioned (pct . negate $ 200) nil)
            ]
