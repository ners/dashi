{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section where

import Dashi.Util
import Data.Text qualified as Text
import GHC.Generics (Generic)
import Miso
import Miso.Html.Element (section_)
import Miso.Html.Property (id_)
import Section.Avatar qualified as Avatar
import Section.Button qualified as Button
import Section.Diagram qualified as Dagram
import Section.Form qualified as Form
import Section.Icon qualified as Icon
import Section.Message qualified as Message
import Section.Overview qualified as Overview
import Prelude hiding (init)

data SectionId
    = Overview
    | Avatar
    | Button
    | Diagram
    | Form
    | Icon
    | Message
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
        Message -> wrapper +> Message.message
  where
    currentStr = toMisoString . Text.toLower . ishow $ current
    wrapper = section_ [key_ currentStr, id_ currentStr]
