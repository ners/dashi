{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.ProgressBar where

import Dashi.Components.Heading
import Dashi.Components.ProgressBar
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.CSS (styleInline_)
import Miso.Html.Element (div_, p_, section_)
import Miso.String qualified as MisoString

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

progressBar :: Component parent Model Action
progressBar = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Progress bar"
        , p_
            []
            [ text
                "A progress bar shows the duration of a system process, such as saving or processing changes, uploading and downloading files, and loading or updating an application."
            ]
        , p_
            []
            [ text
                "Use a progress bar when the process is complex or has a long wait time, and you can determine the percentage of the process that has been completed."
            ]
        , p_ [] [text "For short loading times, use a spinner instead."]
        , div_
            [ styleInline_ "display: flex; flex-direction: column; gap: var(--dashi-space-s);"
            ]
            . mconcat
            $ [ [ widget . Heading Medium . MisoString.toUpper . tokenName $ size
                , widget
                    ProgressBar
                        { value = Determinate{value = 17, max = 100}
                        , size
                        , appearance = Default
                        }
                , widget ProgressBar{value = Indeterminate, size, appearance = Default}
                ]
              | size <- [minBound .. maxBound]
              ]
        ]
