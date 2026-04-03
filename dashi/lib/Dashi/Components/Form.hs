{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Form where

import Clay hiding
    ( fullWidth
    , legend
    , name
    , not
    , option
    , required
    , selected
    , span_
    , type_
    )
import Clay qualified hiding (not)
import Dashi.Components.Checkbox (CheckboxGroup)
import Dashi.Components.Message
    ( Icon (DefaultIcon)
    , Message (..)
    , MessageSize (FormMessage)
    )
import Dashi.Components.Radio (RadioGroup)
import Dashi.Prelude hiding (has, (#), (&), (**))
import Dashi.Style.Text (TextColour (TextColour))
import Dashi.Style.Tokens
import Dashi.Style.Util
import Miso.Html.Element (fieldset_, label_, legend_, span_)
import Miso.Html.Property (class_, required_)

data FormField w model action = FormField
    { legend :: [View model action]
    , required :: Bool
    , field :: w
    , messages :: [(Appearance, MisoString)]
    }

viewMessage :: (Appearance, MisoString) -> View model action
viewMessage (appearance, Just -> secondary) =
    widget
        Message
            { size = FormMessage
            , icon = Just DefaultIcon
            , title = Nothing
            , ..
            }

viewWithLegend
    :: (Widget w model action)
    => [Attribute action]
    -> FormField w model action
    -> View model action
viewWithLegend attrs FormField{..} =
    fieldset_ [class_ "form-field"]
        $ [legend_ [] legend | not . null $ legend]
        <> [widget' ([required_ True | required] <> attrs) field]
        <> (viewMessage <$> messages)

viewWithLabel
    :: (Widget w model action)
    => [Attribute action]
    -> FormField w model action
    -> View model action
viewWithLabel attrs FormField{..} =
    fieldset_ [class_ "form-field"]
        $ label_
            []
            ( [span_ [class_ "legend"] legend | not . null $ legend]
                <> [widget' ([required_ True | required] <> attrs) field]
            )
        : (viewMessage <$> messages)

instance (Widget w model action) => Widget (FormField w model action) model action where
    widget' = viewWithLabel
    style = pure ()

instance {-# OVERLAPPING #-} Widget (FormField () model action) model action where
    widget' = viewWithLegend
    style = do
        form ? do
            display flex
            flexDirection column
            gap' Small
            paddingAll' XSmall
        ".form-field" ? do
            display flex
            flexDirection column
            rowGap' XSmall
        Clay.legend <> (Clay.label ** ".legend") ? do
            display block
            fullWidth
            fontWeight $ weight 500
            fontSize' Small
            marginBottom . token $ Space XSmall
        let requiredChild = self # Clay.required
        ( Clay.legend
                # has (self |+ requiredChild)
                <> (Clay.label # has requiredChild)
                ** ".legend"
            )
            ? after
            & do
                fontWeight $ weight 300
                content $ stringContent "*"
                color' $ TextColour Danger
                marginLeft . token $ Space XSmall

instance
    {-# OVERLAPPING #-}
    (Eq o)
    => Widget (FormField (CheckboxGroup o model action) model action) model action
    where
    widget' = viewWithLegend
    style = pure ()

instance
    {-# OVERLAPPING #-}
    (Eq o)
    => Widget (FormField (RadioGroup o model action) model action) model action
    where
    widget' = viewWithLegend
    style = pure ()
