module Section.Unknown where

import Dashi.Components.Heading
import Dashi.Prelude
import Dashi.Style.Tokens
import Miso.Html.Element

unknown :: View model action
unknown =
    section_
        []
        [ widget $ Heading Large "404"
        , p_ [] ["The page you are looking for is not there."]
        ]
