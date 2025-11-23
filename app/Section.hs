{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section where

import Dashi.Util
import Data.Generics.Labels ()
import Data.Generics.Product.Fields (HasField')
import Data.Text qualified as Text
import GHC.Generics (Generic)
import Miso
import Miso.Html.Element (div_)
import Miso.Html.Property (id_)
import Section.Avatar qualified as Avatar
import Section.Button qualified as Button
import Section.Checkbox qualified as Checkbox
import Section.Form qualified as Form
import Section.Icon qualified as Icon
import Section.Link qualified as Link
import Section.Message qualified as Message
import Section.Overview qualified as Overview
import Section.Plot qualified as Plot
import Section.ProgressBar qualified as ProgressBar
import Section.Radio qualified as Radio
import Section.Range qualified as Range
import Section.Select qualified as Select
import Section.Spinner qualified as Spinner
import Section.Switch qualified as Switch
import Section.Tabs qualified as Tabs
import Section.TextField qualified as TextField
import Prelude hiding (init)

data SectionId
    = Overview
    | Avatar
    | Button
    | Checkbox
    | Form
    | Icon
    | Link
    | Message
    | Plot
    | ProgressBar
    | Radio
    | Range
    | Select
    | Spinner
    | Switch
    | Tabs
    | TextField
    deriving stock (Eq, Show, Bounded, Enum)

data Model = Model
    { current :: SectionId
    , form :: Form.Model
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { current = Overview
        , form = Form.initialModel
        }

data Action = NoOp

view :: Model -> View Model Action
view Model{..} =
    case current of
        Overview -> wrapper +> Overview.overview
        Avatar -> wrapper +> Avatar.avatar
        Button -> wrapper +> Button.button
        Plot -> wrapper +> Plot.plot
        Form -> wrapper +> Form.form #form form
        Icon -> wrapper +> Icon.icon
        Link -> wrapper +> Link.link
        Message -> wrapper +> Message.message
        Checkbox -> wrapper +> Checkbox.checkbox
        ProgressBar -> wrapper +> ProgressBar.progressBar
        Radio -> wrapper +> Radio.radio
        Range -> wrapper +> Range.range
        Select -> wrapper +> Select.select
        Switch -> wrapper +> Switch.switch
        Spinner -> wrapper +> Spinner.spinner
        Tabs -> wrapper +> Tabs.tabs
        TextField -> wrapper +> TextField.textField
  where
    currentStr :: MisoString
    currentStr = toMisoString . Text.toLower . ishow $ current
    wrapper :: [View Model Action] -> View Model Action
    wrapper = div_ [key_ currentStr, id_ currentStr]

section :: (HasField' "section" parent Model) => Model -> Component parent Model Action
section model =
    (component model Section.update Section.view)
        { bindings = [#section <---> id]
        }

update :: Action -> Effect parent Model Action
update NoOp = pure ()
