{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section.Button where

import Dashi.Components.Button
import Dashi.Components.Button qualified as Button
import Dashi.Components.Heading
import Dashi.Components.Icon (Icon (..), Weight (..))
import Dashi.Components.Icon qualified as Icon
import Dashi.Components.Util
import Dashi.Prelude hiding (update, view)
import Dashi.Style.Tokens
import Dashi.Util
import Miso.Html.Element (div_, p_, section_)
import Miso.Html.Property (class_, disabled_)

data Model = Model
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel = Model

data Action = NoOp

button :: Component parent props Model Action
button = component initialModel update view

update :: Action -> Effect parent props Model Action
update NoOp = pure ()

view :: props -> Model -> View Model Action
view _ Model =
    section_ []
        . mconcat
        $ [ pure . widget $ Heading Large "Button"
          , pure
                . p_ []
                . pure
                . text
                $ "A button triggers an event or action. They let users know what will happen next."
          , mconcat
                [ [widget . Heading Medium $ appearanceStr]
                    <> description appearance
                    <> [ div_
                            [class_ "grid"]
                            [ div_ []
                                . pure
                                $ widget' @(Button Model Action)
                                    [attr]
                                    Button
                                        { size = Button.DefaultSize
                                        , appearance
                                        , label = [widget (iconFor appearance) | hasIcon] <> [text appearanceStr]
                                        , onClick = Just NoOp
                                        }
                            | attr <- [emptyAttr_, ariaBusy_ True, disabled_]
                            , hasIcon <- [False, True]
                            ]
                       ]
                | appearance <- [minBound .. maxBound]
                , let appearanceStr = capitalise . tokenName $ appearance
                      iconFor Default = Icon Fill Icon.Star
                      iconFor Primary = Icon Fill Icon.PaperPlaneTilt
                      iconFor Subtle = Icon Bold Icon.CaretLeft
                      iconFor Success = Icon Fill Icon.CheckFat
                      iconFor Warning = Icon Fill Icon.Warning
                      iconFor Danger = Icon Fill Icon.Trash
                      iconFor Discovery = Icon Fill Icon.Sparkle
                ]
          ]

description :: Appearance -> [View Model Action]
description =
    fmap (p_ [] . pure . text) . \case
        Default ->
            [ "Use default buttons for most actions that aren't the main call to action for a page or area. Default buttons are less prominent than primary buttons."
            ]
        Subtle ->
            [ "Use a subtle button with a primary button for secondary actions."
            , "Subtle buttons are best used in spaces where it's already clear items can be interacted with, like toolbars or groups of buttons next to each other. Avoid using them in other situations, as they aren't as obviously clickable as other button styles."
            ]
        Primary ->
            [ "Use a primary button to call attention to a form submission or to highlight the most important call to action on a page. They represent what the user should do next in a workflow."
            , "Primary buttons should only appear once per area, but not every screen needs a primary button."
            ]
        Success ->
            [ "A success button can be used for confirming successful operations, continuing after a completed task, or reinforcing positive feedback moments."
            , "They should be used after an action succeeds or when the action itself is inherently confirming success."
            ]
        Warning ->
            [ "Warning buttons confirm actions that may cause a significant change or a loss of data."
            , "Warnings alert people of a problem that might happen if they proceed. These appearances are often used in confirmation modals."
            ]
        Danger ->
            [ "A danger button appears as a final confirmation for a destructive and irreversible action, such as deleting."
            ]
        Discovery ->
            [ "A discovery button can be used as the call to action for new experiences."
            ]
