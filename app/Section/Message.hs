{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Message where

import Dashi.Components.Heading
import Dashi.Components.Message
import Dashi.Components.Widget
import Dashi.Style.Tokens
import GHC.Generics (Generic)
import Miso hiding (update, view)
import Miso.Html.Element (p_, section_)
import Prelude

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

message :: Component parent Model Action
message = component initialModel update view

update :: Action -> Effect parent Model Action
update NoOp = pure ()

view :: Model -> View Model Action
view Model =
    section_
        []
        [ widget $ Heading Large "Message"
        , p_ [] [text "A message lets users know when important information is available or when an action is required."]
        , widget $ Heading Medium "Inline message"
        , widget
            Message
                { size = InlineMessage
                , appearance = Primary
                , title = Just "Software update"
                , secondary = Just "You've been upgraded to version 5.2"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Warning
                , title = Nothing
                , secondary = Just "Your bill may increase"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Danger
                , title = Nothing
                , secondary = Just "Username taken"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Success
                , title = Nothing
                , secondary = Just "Files have been added"
                }
        , widget
            Message
                { size = InlineMessage
                , appearance = Discovery
                , title = Nothing
                , secondary = Nothing
                }
        , widget $ Heading Medium "Section message"
        , widget
            Message
                { size = SectionMessage
                , appearance = Primary
                , title = Just "Editing is restricted"
                , secondary = Just "You're not allowed to change these restrictions. It's either due to the restrictions on the page, or permission settings for this space."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Warning
                , title = Just "Cannot connect to the database"
                , secondary = Just "We're unable to save any progress at this time. Please try again later."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Success
                , title = Nothing
                , secondary = Just "The file has been uploaded."
                }
        , widget
            Message
                { size = SectionMessage
                , appearance = Danger
                , title = Just "This account has been permanently deleted"
                , secondary = Just "The user `IanAtlas` no longer has access to Atlassian services."
                }
        ]
