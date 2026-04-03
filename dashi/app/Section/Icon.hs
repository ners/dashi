{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Icon where

import Dashi.Components.Heading
import Dashi.Components.Icon
import Dashi.Components.Radio (RadioGroup (..))
import Dashi.Components.TextField (TextField (..), Type (Text))
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Data.List qualified as List
import Miso.Html.Element (a_, div_, p_, section_)
import Miso.Html.Property (class_, href_, placeholder_, target_, title_)
import Miso.String qualified as MisoString

data Model = Model
    { filter :: MisoString
    , weight :: Weight
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { filter = ""
        , weight = Regular
        }

data Action
    = NoOp
    | SetFilter MisoString
    | SetWeight Weight

icon :: Component parent Model Action
icon = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update (SetFilter s) = #filter .= s
update (SetWeight w) = #weight .= w

deriving stock instance Show Phosphor

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Icon"
        , p_
            []
            [ text
                "Icons are visual symbols used to represent ideas, objects, or actions. They communicate messages at a glance, afford interactivity, and draw attention to important information."
            ]
        , p_
            []
            [ text
                "Dashi uses the "
            , a_
                [href_ "https://phosphoricons.com", target_ "blank"]
                [ widget $ Icon Fill PhosphorLogo
                , text " Phosphor icon family"
                ]
            , text
                " to provide a versatile, consistent set of icons that help maintain a unified visual language throughout the interface."
            ]
        , div_
            [class_ "controls"]
            [ widget'
                [placeholder_ "Filter"]
                TextField
                    { name = "icon-filter"
                    , type' = Text
                    , value = Just filter
                    , valid = True
                    , onChange = SetFilter
                    }
            , widget @(RadioGroup Weight Model Action)
                RadioGroup
                    { name = "icon-weight"
                    , options = [minBound .. maxBound]
                    , label = pure . ishow
                    , selected = Just weight
                    , onSelect = SetWeight
                    }
            ]
        , div_
            [class_ "grid"]
            [ widget' [title_ s] $ Icon weight i
            | i <- [minBound .. maxBound]
            , let s = ishow i
            , let toLower :: MisoString -> String
                  toLower = fromMisoString . MisoString.toLower
            , List.isInfixOf @Char (toLower filter) (toLower s)
            ]
        ]
