module SectionId where

import Dashi.Prelude hiding (ComponentId)
import Dashi.Util
import Data.List.Extra qualified as List
import Data.Vector.Strict qualified as Vector
import Miso.Html.Element (a_)
import Miso.Html.Event (onClickPrevent)
import Miso.Router (Router (..), Token (..))
import Miso.String qualified as MisoString
import Miso.Util.Parser (ParserT (..))

data SectionId
    = Overview
    | Foundations FoundationId
    | Components ComponentId
    deriving stock (Eq, Show)

data FoundationId
    = Accessibility
    | Colours
    | DesignTokens
    deriving stock (Eq, Show, Bounded, Enum)

data ComponentId
    = Avatar
    | Breadcrumbs
    | Button
    | Checkbox
    | Form
    | Heading
    | Icon
    | Link
    | Message
    | Pagination
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

allSections :: Vector SectionId
allSections =
    mconcat
        [ pure Overview
        , Foundations <$> Vector.fromList [minBound .. maxBound]
        , Components <$> Vector.fromList [minBound .. maxBound]
        ]

instance Enum SectionId where
    toEnum = (Vector.!) allSections
    fromEnum = fromJust . flip Vector.findIndex allSections . (==)

instance Bounded SectionId where
    minBound = toEnum 0
    maxBound = toEnum . pred $ Vector.length allSections

instance Router SectionId where
    fromRoute =
        fmap (CaptureOrPathToken . MisoString.toLower . MisoString.strip)
            . breakAll (== ' ')
            . ishow
    routeParser = Parser \_ -> \case
        [IndexToken] -> pure (Overview, [])
        tokens ->
            maybeToList
                $ List.firstJust
                    (\r -> (r,) <$> List.stripPrefix (fromRoute @SectionId r) tokens)
                    [minBound .. maxBound]

sectionTitle :: SectionId -> MisoString
sectionTitle = capitalise . unpascal . last . MisoString.words . ishow

sectionLink :: (SectionId -> action) -> SectionId -> View model action
sectionLink navigate s =
    a_
        [href_ s, onClickPrevent $ navigate s]
        [text . sectionTitle $ s]
