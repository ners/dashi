{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-partial-fields #-}

module Dashi.Components.ProgressBar where

import Clay hiding (Background, Color, Value, action, fullWidth, max, size, value)
import Dashi.Components.Widget
import Dashi.Style.Colour hiding (Background)
import Dashi.Style.Root (tokenDecl)
import Dashi.Style.Tokens
import Dashi.Style.Util (backgroundColor', borderRadiusAll', fullWidth)
import Data.Foldable (for_)
import Data.Functor ((<&>))
import Data.List qualified as List
import Data.List.NonEmpty (NonEmpty ((:|)))
import Data.Maybe (catMaybes)
import Data.Semigroup (sconcat)
import Data.String (fromString)
import Miso
import Miso.Html.Element (progress_)
import Miso.Html.Property (max_, value_)
import Prelude hiding (max)

data Background = Background
    deriving stock (Eq, Bounded, Enum)

instance Token Background where
    tokenName Background = "progress-background-color"

instance ValueToken Background where
    type ValueType Background = LightDark (Color (Alpha OKLCH) Double)
    tokenValue Background = tokenValue (Text Default) <&> flip setAlpha 0.075

newtype Progress = Progress Appearance
    deriving newtype (Eq, Bounded, Enum)

instance Token Progress where
    tokenName (Progress appearance) =
        fromString . List.intercalate "-" . catMaybes $
            [ Just "progress"
            , Just "color"
            , nonDefaultTokenName appearance
            ]

instance ValueToken Progress where
    type ValueType Progress = LightDark (Color (Alpha OKLCH) Double)
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
                Indeterminate -> []
    style = do
        ":root" ? do
            tokenDecl @Background
            tokenDecl @Progress
        progress ? do
            display block
            fullWidth
            backgroundColor' Background
            for_ @[] [minBound .. maxBound] \size ->
                byToken size & do
                    height . tokenValue . Space $ size
            "::-webkit-progress-bar" & do
                background transparent
            "::-webkit-progress-value" & do
                backgroundColor' $ Progress Default
            "::-moz-progress-bar" & do
                backgroundColor' $ Progress Default
        sconcat (progress :| ((progress #) <$> ["::-webkit-progress-bar", "::-webkit-progress-value"]))
            ? borderRadiusAll' Large
