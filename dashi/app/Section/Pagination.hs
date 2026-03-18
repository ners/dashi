{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Pagination where

import Dashi.Components.Heading
import Dashi.Components.Pagination
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Miso.Html.Element (p_, section_)

newtype Model = Model {page :: Int}
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model{page = 1}

data Action
    = NoOp
    | SetPage Int

pagination :: Component parent Model Action
pagination = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()
update (SetPage page) = #page .= page

view :: Model -> View Model Action
view Model{..} =
    section_
        []
        [ widget $ Heading Large "Pagination"
        , p_
            []
            [ text
                "Pagination allows you to divide large amounts of content into smaller chunks across multiple pages."
            ]
        , widget
            Pagination
                { pages = 10
                , currentPage = page
                , onPageSelect = SetPage
                }
        ]
