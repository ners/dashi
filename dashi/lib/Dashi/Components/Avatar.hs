{-# LANGUAGE OverloadedLists #-}

module Dashi.Components.Avatar where

import Clay hiding
    ( Content
    , action
    , content
    , img
    , shape
    , size
    , span_
    , transparent
    , url
    )
import Clay qualified
import Dashi.Components.Icon ()
import Dashi.Prelude hiding (Image, has, rem, span, (#), (&))
import Dashi.Style.Background (BackgroundColour (BackgroundColour))
import Dashi.Style.Text (TextColour (TextColour))
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (div_, img_, span_)
import Miso.Html.Property (class_, src_)
import Web.Font.MDI (MDI)

data Shape
    = Circle
    | Hexagon
    | Square
    deriving stock (Eq, Bounded, Enum)

instance Token Shape where
    tokenName Circle = "circle"
    tokenName Hexagon = "hexagon"
    tokenName Square = "square"

data Content
    = Image MisoString
    | Icon MDI
    | Initials MisoString

data Avatar = Avatar
    { shape :: Shape
    , size :: SizeToken
    , content :: Content
    }

instance Widget Avatar model action where
    widget' attrs Avatar{..} =
        span_
            (class_ "avatar" : tokenAttr shape : tokenAttr size : attrs)
            [ case content of
                Image url -> image url
                Icon mdi -> widget mdi
                Initials str -> text str
            ]
      where
        image :: MisoString -> View model action
        image = img_ . pure . src_
    style =
        ".avatar" ? do
            "image-rendering" -: "pixelated"
            byTokens \size -> do
                let sizeEm = case size of
                        XSmall -> 1
                        Small -> 1.75
                        Medium -> 2
                        Large -> 2.5
                        XLarge -> 6
                width $ rem sizeEm
                height $ rem sizeEm
                lineHeight $ rem sizeEm
                Clay.fontSize (rem $ sizeEm / 3)
            overflow hidden
            backgroundColor' (BackgroundColour Primary)
            fontWeight $ weight 600
            color' $ TextColour Subtle
            display inlineFlex
            alignItems center
            justifyContent center
            Clay.img ? do
                width $ pct 100
                height $ pct 100
            byToken Square & do
                borderRadiusAll' Medium
            byToken Circle & do
                borderRadiusAll $ vh 100
            byToken Hexagon & do
                "clip-path"
                    -: "polygon(45% 1.33975%, 46.5798% 0.60307%, 48.26352% 0.15192%, 50% 0%, 51.73648% 0.15192%, 53.4202% 0.60307%, 55% 1.33975%, 89.64102% 21.33975%, 91.06889% 22.33956%, 92.30146% 23.57212%, 93.30127% 25%, 94.03794% 26.5798%, 94.48909% 28.26352%, 94.64102% 30%, 94.64102% 70%, 94.48909% 71.73648%, 94.03794% 73.4202%, 93.30127% 75%, 92.30146% 76.42788%, 91.06889% 77.66044%, 89.64102% 78.66025%, 55% 98.66025%, 53.4202% 99.39693%, 51.73648% 99.84808%, 50% 100%, 48.26352% 99.84808%, 46.5798% 99.39693%, 45% 98.66025%, 10.35898% 78.66025%, 8.93111% 77.66044%, 7.69854% 76.42788%, 6.69873% 75%, 5.96206% 73.4202%, 5.51091% 71.73648%, 5.35898% 70%, 5.35898% 30%, 5.51091% 28.26352%, 5.96206% 26.5798%, 6.69873% 25%, 7.69854% 23.57212%, 8.93111% 22.33956%, 10.35898% 21.33975%)"

data AvatarItem = AvatarItem
    { avatar :: Avatar
    , primaryText :: Maybe MisoString
    , secondaryText :: Maybe MisoString
    }

instance Widget AvatarItem model action where
    widget' attrs AvatarItem{..} =
        div_
            (class_ "avatar-item" : attrs)
            . mconcat
            $ [ [widget avatar]
              , span_ [class_ "primary"] . pure . text <$> maybeToList primaryText
              , span_ [class_ "secondary"] . pure . text <$> maybeToList secondaryText
              ]
    style =
        ".avatar-item" ? do
            ".avatar" ? ("grid-area" -: "avatar")
            ".primary" ? fontWeight (weight 500)
            ".secondary" ? do
                color' $ TextColour Subtle
                fontSize' Small
            display flex
            columnGap' Small
            alignItems center
            alignContent center
            flexDirection row
            sconcat [has ".primary", has ".secondary"] & do
                display grid
                gridTemplateAreas
                    [ ["avatar", "primary"]
                    , ["avatar", "secondary"]
                    ]
                "grid-auto-columns" -: "max-content"
                ".primary" ? do
                    "grid-area" -: "primary"
                    alignSelf $ AlignSelfValue "end"
                ".secondary" ? do
                    "grid-area" -: "secondary"
                    alignSelf $ AlignSelfValue "start"
            has (".avatar" # byToken XLarge) & fontSize' XLarge
