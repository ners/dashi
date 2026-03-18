{-# OPTIONS_GHC -Wno-missing-role-annotations #-}

module Dashi.Components.Pagination where

import Clay hiding (Color, action, button, disabled, href, icon, label, span_)
import Clay qualified
import Dashi.Components.Button (Button (..), ButtonSize (..))
import Dashi.Components.Button qualified as Button
import Dashi.Components.Icon
    ( MDI (MdiChevronLeft, MdiChevronRight, MdiDotsHorizontal)
    , iconContent
    , iconStyle
    )
import Dashi.Components.Util (ariaCurrent_)
import Dashi.Prelude hiding ((#), (&), (|>))
import Dashi.Style.Colour qualified as Colour
import Dashi.Style.Tokens
import Dashi.Style.Util (ariaCurrent, color')
import Miso.Html.Element (div_, span_)
import Miso.Html.Property (class_, disabled_)

data Pagination action = Pagination
    { pages :: Int
    , currentPage :: Int
    , onPageSelect :: Int -> action
    }

instance Widget (Pagination action) model action where
    widget' attrs Pagination{..} =
        div_ (class_ "pagination" : attrs)
            $ mconcat
                [ pure . button (Just MdiChevronLeft) $ pred currentPage
                , pageButtons
                , pure . button (Just MdiChevronRight) $ succ currentPage
                ]
      where
        pageButtons :: [View model action]
        pageButtons
            | pages < 1 = []
            | pages <= 7 = page <$> [1 .. pages]
            | currentPage < 5 = (page <$> [1 .. 5]) <> [ellipsis, page pages]
            | currentPage > pages - 4 =
                [page 1, ellipsis] <> (page <$> [pages - 4 .. pages])
            | otherwise =
                [page 1, ellipsis]
                    <> (page <$> [currentPage - 1 .. currentPage + 1])
                    <> [ellipsis, page pages]
        ellipsis :: View model action
        ellipsis = span_ [class_ "ellipsis"] []
        page = button Nothing
        button :: Maybe MDI -> Int -> View model action
        button icon page' =
            let
                current, disabled :: Bool
                current = page' == currentPage
                disabled = page' < 1 || page' > pages
             in
                widget' @(Button model action)
                    ([ariaCurrent_ True | current] <> [disabled_ | disabled])
                    Button
                        { size = DefaultSize
                        , appearance = Default
                        , label = [maybe (text . toMisoString $ page') widget icon]
                        , onClick =
                            if current || disabled
                                then Nothing
                                else Just (onPageSelect page')
                        }
    style =
        ".pagination" ? do
            display flex
            flexDirection row
            Clay.button ? do
                Button.appearanceStyle Subtle
                Button.sizeStyle IconButton
                minWidth $ em 2.5
                ariaCurrent True & do
                    Button.appearanceStyle Default
                    color' $ Colour.Text Primary
            ".ellipsis" ? do
                iconStyle
                before & content (iconContent MdiDotsHorizontal)
                color' $ Colour.Text Subtle
                lineHeight $ unitless 1.6
                width $ em 1.67
                opacity 0.5
