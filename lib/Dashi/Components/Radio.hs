{-# OPTIONS_GHC -Wno-missing-role-annotations #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Dashi.Components.Radio where

import Clay hiding (fullWidth, legend, name, option, span_, type_)
import Clay qualified
import Dashi.Components.Icon (iconContent)
import Dashi.Components.Message (Message (..), MessageSize (FormMessage))
import Dashi.Components.Util
import Dashi.Components.Widget
import Dashi.Style.Tokens hiding (Background)
import Dashi.Style.Util
import Miso (MisoString, View, text)
import Miso.Html.Element (fieldset_, input_, label_, legend_, span_)
import Miso.Html.Property (class_, name_, selected_, type_)
import Web.Font.MDI (MDI (MdiRadioboxBlank, MdiRadioboxMarked))
import Prelude

data Radio a = Radio
    { legend :: MisoString
    , name :: MisoString
    , options :: [a]
    , selectedOption :: Maybe a
    , optionLabel :: forall model action. a -> [View model action]
    , messages :: [(Appearance, MisoString)]
    }

instance (Eq a) => Widget (Radio a) where
    widget' attrs Radio{..} =
        fieldset_ [class_ "radio-field"] . mconcat $
            [ pure $ legend_ [class_ "required" | hasRequired attrs] [text legend]
            , option <$> options
            , message <$> messages
            ]
      where
        option :: a -> View model action
        option o =
            label_
                []
                [ input_ $ type_ "radio" : name_ name : [selected_ True | Just o == selectedOption]
                , span_ [class_ "label"] $ optionLabel o
                ]
        message :: (Appearance, MisoString) -> View model action
        message (appearance, Just -> secondary) = widget Message{size = FormMessage, title = Nothing, ..}

    style = do
        -- Shared style is applied in the Checkbox component
        input # ("type" @= "radio") ? do
            before & content (iconContent MdiRadioboxBlank)
            checked <> before & do
                color' BorderFocused
                content $ iconContent MdiRadioboxMarked
        ".radio-field" ? do
            display flex
            flexDirection column
            rowGap' XSmall
            Clay.legend ? do
                display block
                fullWidth
                fontWeight $ weight 600
                fontSize $ pct 85
                marginBottom . token $ Space Small
                ".required" <> after & do
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
