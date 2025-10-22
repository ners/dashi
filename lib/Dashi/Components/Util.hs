{-# LANGUAGE TemplateHaskell #-}

module Dashi.Components.Util where

import Control.Category ((>>>))
import Control.Lens (makePrisms, toListOf)
import Data.Aeson qualified as Aeson
import Data.List qualified as List
import Miso
import Miso.Html.Property (aria_)
import Prelude

makePrisms ''Attribute

props :: [Attribute action] -> [(MisoString, Aeson.Value)]
props = toListOf $ traverse . _Property

findProp :: MisoString -> [Attribute action] -> Maybe Aeson.Value
findProp k = List.lookup k . props

isBoolProp :: MisoString -> [Attribute action] -> Bool
isBoolProp k =
    findProp k >>> maybe False \case
        Aeson.Bool True -> True
        Aeson.String "true" -> True
        _ -> False

isAriaBusy :: [Attribute action] -> Bool
isAriaBusy = isBoolProp "aria-busy"

isRequired :: [Attribute action] -> Bool
isRequired = isBoolProp "required"

ariaBusy_ :: Attribute action
ariaBusy_ = aria_ "busy" "true"
