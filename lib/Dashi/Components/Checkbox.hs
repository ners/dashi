{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Checkbox where

import Clay hiding (fullWidth, legend, name, option, span_, type_)
import Clay qualified
import Dashi.Components.Icon (iconContent, iconFont)
import Dashi.Components.Message (Message (..), MessageSize (FormMessage))
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Data.Maybe (maybeToList)
import Miso (MisoString, View, text)
import Miso.Html.Element (fieldset_, input_, label_, legend_, span_)
import Miso.Html.Property (class_, name_, selected_, type_)
import Web.Font.MDI (MDI (MdiCheckboxBlankOutline, MdiCheckboxMarked))
import Prelude

data Checkbox a = Checkbox
    { legend :: Maybe MisoString
    , name :: MisoString
    , options :: [a]
    , selectedOptions :: [a]
    , optionLabel :: forall model action. a -> [View model action]
    , messages :: [(Appearance, MisoString)]
    }

instance (Eq a) => Widget (Checkbox a) where
    widget' attrs Checkbox{..} =
        fieldset_ [class_ "checkbox-field"] . mconcat $
            [ legend_ [class_ "required" | hasRequired attrs] . pure . text <$> maybeToList legend
            , option <$> options
            , message <$> messages
            ]
      where
        option :: a -> View model action
        option o =
            label_
                []
                [ input_ $ type_ "checkbox" : name_ name : [selected_ True | o `elem` selectedOptions]
                , span_ [class_ "label"] $ optionLabel o
                ]
        message :: (Appearance, MisoString) -> View model action
        message (appearance, Just -> secondary) = widget Message{size = FormMessage, title = Nothing, ..}

    style = do
        input # ("type" @= "checkbox") <> input # ("type" @= "radio") ? do
            pressable
            iconFont
            color' InputBorder
            transition "color" (ms 100) easeInOut (sec 0)
        input # ("type" @= "checkbox") ? do
            before & content (iconContent MdiCheckboxBlankOutline)
            checked
                <> before
                & do
                    color' BorderFocused
                    content $ iconContent MdiCheckboxMarked
        ".checkbox-field" ? do
            display flex
            flexDirection column
            rowGap' XSmall
            Clay.legend ? do
                display block
                fullWidth
                fontWeight $ weight 600
                fontSize $ pct 85
                marginBottom . token $ Space Small
                ".required"
                    <> after
                    & do
                        fontWeight $ weight 400
                        content $ stringContent "*"
                        color' $ Text Danger
                        marginLeft . token $ Space XSmall
            Clay.label ? do
                pressable
                display flex
                flexDirection row
                alignItems center
                columnGap' XSmall
                fullWidth
                paddingLeft . token $ Space XSmall
