{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section where

import Dashi.Util
import Data.Text qualified as Text
import GHC.Generics (Generic)
import Miso
import Miso.Html.Element (div_)
import Miso.Html.Property (id_)
import Section.Avatar qualified as Avatar
import Section.Button qualified as Button
import Section.Checkbox qualified as Checkbox
import Section.Diagram qualified as Dagram
import Section.Form qualified as Form
import Section.Icon qualified as Icon
import Section.Link qualified as Link
import Section.Message qualified as Message
import Section.Overview qualified as Overview
import Section.Radio qualified as Radio
import Section.Spinner qualified as Spinner
import Section.Switch qualified as Switch
import Section.TextField qualified as TextField
import Prelude hiding (init)

data SectionId
    = Overview
    | Avatar
    | Button
    | Checkbox
    | Diagram
    | Form
    | Icon
    | Link
    | Message
    | Radio
    | Spinner
    | Switch
    | TextField
    deriving stock (Eq, Show, Bounded, Enum)

data Model = Model
    { current :: SectionId
    }
    deriving stock (Generic, Eq, Show)

initialModel :: Model
initialModel =
    Model
        { current = Overview
        }

data Action
    = NoOp
    | OverviewAction Overview.Action

view :: Model -> View parent action
view Model{..} =
    case current of
        Overview -> wrapper +> Overview.overview
        Avatar -> wrapper +> Avatar.avatar
        Button -> wrapper +> Button.button
        Diagram -> wrapper +> Dagram.diagram
        Form -> wrapper +> Form.form
        Icon -> wrapper +> Icon.icon
        Link -> wrapper +> Link.link
        Message -> wrapper +> Message.message
        Checkbox -> wrapper +> Checkbox.checkbox
        Radio -> wrapper +> Radio.radio
        Switch -> wrapper +> Switch.switch
        Spinner -> wrapper +> Spinner.spinner
        TextField -> wrapper +> TextField.textField
  where
    currentStr = toMisoString . Text.toLower . ishow $ current
    wrapper = div_ [key_ currentStr, id_ currentStr]
