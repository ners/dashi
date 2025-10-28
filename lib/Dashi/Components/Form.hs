{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Form where

import Clay hiding (fullWidth, legend, name, not, option, required, selected, span_, type_)
import Clay qualified hiding (not)
import Dashi.Components.Checkbox (CheckboxGroup)
import Dashi.Components.Message (Message (..), MessageSize (FormMessage))
import Dashi.Components.Radio (RadioGroup)
import Dashi.Components.Widget
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Miso (Attribute, MisoString, View)
import Miso.Html.Element (fieldset_, label_, legend_, span_)
import Miso.Html.Property (class_, required_)
import Prelude hiding ((**))

data FormField w = FormField
    { legend :: forall model action. [View model action]
    , required :: Bool
    , field :: w
    , messages :: [(Appearance, MisoString)]
    }

viewMessage :: (Appearance, MisoString) -> View model action
viewMessage (appearance, Just -> secondary) = widget Message{size = FormMessage, title = Nothing, ..}

viewWithLegend :: (Widget w model action) => [Attribute action] -> FormField w -> View model action
viewWithLegend attrs FormField{..} =
    fieldset_ [class_ "form-field"] $
        [legend_ [] legend | not . null $ legend] <> [widget' ([required_ True | required] <> attrs) field] <> (viewMessage <$> messages)

viewWithLabel :: (Widget w model action) => [Attribute action] -> FormField w -> View model action
viewWithLabel attrs FormField{..} =
    fieldset_ [class_ "form-field"] $
        label_ [] ([span_ [class_ "legend"] legend | not . null $ legend] <> [widget' ([required_ True | required] <> attrs) field])
            : (viewMessage <$> messages)

instance (Widget w model action) => Widget (FormField w) model action where
    widget' = viewWithLabel
    style = pure ()

instance {-# OVERLAPPING #-} Widget (FormField ()) model action where
    widget' = viewWithLegend
    style = do
        ".form-field" ? do
            display flex
            flexDirection column
            rowGap' XSmall
        Clay.legend <> (Clay.label ** ".legend") ? do
            display block
            fullWidth
            fontWeight $ weight 600
            fontSize' Small
            marginBottom . token $ Space Small
        let requiredChild = self # Clay.required
        (Clay.legend # has (self |+ requiredChild) <> (Clay.label # has requiredChild) ** ".legend")
            ? after
            & do
                fontWeight $ weight 400
                content $ stringContent "*"
                color' $ Text Danger
                marginLeft . token $ Space XSmall

instance {-# OVERLAPPING #-} (Eq o) => Widget (FormField (CheckboxGroup o)) model action where
    widget' = viewWithLegend
    style = pure ()

instance {-# OVERLAPPING #-} (Eq o) => Widget (FormField (RadioGroup o)) model action where
    widget' = viewWithLegend
    style = pure ()
