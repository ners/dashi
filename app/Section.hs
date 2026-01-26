{-# LANGUAGE OverloadedLists #-}
{-# OPTIONS_GHC -Wno-term-variable-capture #-}

module Section where

import Dashi.Prelude hiding (ComponentId, init)
import Dashi.Util
import Data.Generics.Labels ()
import Data.List.Extra qualified as List
import Data.Sequence (Seq)
import Data.Sequence qualified as Seq
import Miso.Html.Element (div_)
import Miso.Html.Property (id_)
import Miso.Router (Router (..), Token (..))
import Miso.String qualified as MisoString
import Miso.Util.Parser (ParserT (..))
import Section.Accessibility qualified as Accessibility
import Section.Avatar qualified as Avatar
import Section.Button qualified as Button
import Section.Checkbox qualified as Checkbox
import Section.DesignTokens qualified as DesignTokens
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

data SectionId
    = Overview
    | Foundations FoundationId
    | Components ComponentId
    deriving stock (Eq, Show)

allSections :: Seq SectionId
allSections =
    mconcat
        [ pure Overview
        , Foundations <$> [minBound .. maxBound]
        , Components <$> [minBound .. maxBound]
        ]

instance Enum SectionId where
    toEnum = Seq.index allSections
    fromEnum = fromJust . flip Seq.elemIndexL allSections

instance Bounded SectionId where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Seq.length allSections

data FoundationId
    = Accessibility
    | DesignTokens
    deriving stock (Eq, Show, Bounded, Enum)

data ComponentId
    = Avatar
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
    deriving stock (Generic, Eq, Show, Bounded, Enum)

instance Router SectionId where
    fromRoute = fmap (CaptureOrPathToken . MisoString.toLower . MisoString.strip) . breakAll (== ' ') . ishow
    routeParser = Parser \_ tokens ->
        maybeToList $ List.firstJust (\r -> (r,) <$> List.stripPrefix (fromRoute @SectionId r) tokens) [minBound .. maxBound]

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
    div_ [key_ currentStr, id_ currentStr] . pure $ case current of
        Overview -> mount Overview.overview
        Foundations Accessibility -> mount Accessibility.accessibility
        Foundations DesignTokens -> mount DesignTokens.tokens
        Components Avatar -> mount Avatar.avatar
        Components Button -> mount Button.button
        Components Form -> mount $ Form.form #form form
        Components Icon -> mount Icon.icon
        Components Link -> mount Link.link
        Components Message -> mount Message.message
        Components Checkbox -> mount Checkbox.checkbox
        Components Plot -> mount Plot.plot
        Components ProgressBar -> mount ProgressBar.progressBar
        Components Radio -> mount Radio.radio
        Components Range -> mount Range.range
        Components Select -> mount Select.select
        Components Switch -> mount Switch.switch
        Components Spinner -> mount Spinner.spinner
        Components Tabs -> mount Tabs.tabs
        Components TextField -> mount TextField.textField
  where
    currentStr :: MisoString
    currentStr = toMisoString . MisoString.replace " " "-" . MisoString.toLower . ishow $ current

section :: Lens' parent Model -> Model -> Component parent Model Action
section l model =
    (component model Section.update Section.view)
        { bindings = [l <---> id]
        }

update :: Action -> Effect parent Model Action
update NoOp = pure ()
