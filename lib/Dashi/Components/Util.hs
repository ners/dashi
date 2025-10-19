{-# LANGUAGE TemplateHaskell #-}

module Dashi.Components.Util where

import Control.Lens (makePrisms, toListOf)
import Data.Aeson qualified as Aeson
import Data.List qualified as List
import Miso
import Prelude

makePrisms ''Attribute

props :: [Attribute action] -> [(MisoString, Aeson.Value)]
props = toListOf $ traverse . _Property

findProp :: MisoString -> [Attribute action] -> Maybe Aeson.Value
findProp k = List.lookup k . props

isAriaBusy :: [Attribute action] -> Bool
isAriaBusy = (Just (Aeson.String "true") ==) . findProp "aria-busy"

isRequired :: [Attribute action] -> Bool
isRequired = (Just (Aeson.Bool True) ==) . findProp "required"
