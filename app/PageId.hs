module PageId where

import Prelude

data PageId
    = Overview
    | Avatars
    | Buttons
    | Icons
    deriving stock (Eq, Bounded, Enum)
