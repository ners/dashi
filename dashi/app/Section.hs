{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section where

import Dashi.Prelude hiding (ComponentId, init)
import Miso.Html.Element (div_)
import Miso.Html.Property (id_)
import Miso.String qualified as MisoString
import Section.Accessibility qualified as Accessibility
import Section.Avatar qualified as Avatar
import Section.Breadcrumbs qualified as Breadcrumbs
import Section.Button qualified as Button
import Section.Checkbox qualified as Checkbox
import Section.Colours qualified as Colours
import Section.DesignTokens qualified as DesignTokens
import Section.Form qualified as Form
import Section.Heading qualified as Heading
import Section.Icon qualified as Icon
import Section.Link qualified as Link
import Section.Message qualified as Message
import Section.Overview qualified as Overview
import Section.Pagination qualified as Pagination
import Section.Plot qualified as Plot
import Section.ProgressBar qualified as ProgressBar
import Section.Radio qualified as Radio
import Section.Range qualified as Range
import Section.Select qualified as Select
import Section.Spinner qualified as Spinner
import Section.Switch qualified as Switch
import Section.Tabs qualified as Tabs
import Section.TextField qualified as TextField
import Section.Unknown qualified as Unknown
import SectionId

data Model = Model
    { current :: Maybe SectionId
    , form :: Form.Model
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { current = Nothing
        , form = Form.initialModel
        }

data Action = NoOp

view :: props -> Model -> View Model Action
view _ Model{..} =
    div_ [key_ currentKey, id_ currentKey] . pure $ flip (maybe Unknown.unknown) current \case
        Overview -> mount_ Overview.overview
        Foundations Accessibility -> mount_ Accessibility.accessibility
        Foundations Colours -> mount_ Colours.colours
        Foundations DesignTokens -> mount_ DesignTokens.tokens
        Components Avatar -> mount_ Avatar.avatar
        Components Breadcrumbs -> mount_ Breadcrumbs.breadcrumbs
        Components Button -> mount_ Button.button
        Components Checkbox -> mount_ Checkbox.checkbox
        Components Form -> mount_ $ Form.form #form form
        Components Heading -> mount_ Heading.heading
        Components Icon -> mount_ Icon.icon
        Components Link -> mount_ Link.link
        Components Message -> mount_ Message.message
        Components Pagination -> mount_ Pagination.pagination
        Components Plot -> mount_ Plot.plot
        Components ProgressBar -> mount_ ProgressBar.progressBar
        Components Radio -> mount_ Radio.radio
        Components Range -> mount_ Range.range
        Components Select -> mount_ Select.select
        Components Spinner -> mount_ Spinner.spinner
        Components Switch -> mount_ Switch.switch
        Components Tabs -> mount_ Tabs.tabs
        Components TextField -> mount_ TextField.textField
  where
    currentKey = maybe "unknown" sectionKey current
    sectionKey :: SectionId -> MisoString
    sectionKey = toMisoString . MisoString.replace " " "-" . MisoString.toLower . ishow

section :: Lens' parent Model -> Model -> Component parent props Model Action
section l model =
    (component model Section.update Section.view)
        { bindings = [l <---> id]
        }

update :: Action -> Effect parent props Model Action
update NoOp = pure ()
