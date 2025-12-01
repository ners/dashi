{-# LANGUAGE TemplateHaskell #-}

module Dashi.Components.Util where

import Control.Lens (makePrisms, toListOf)
import Control.Monad ((>=>))
import Dashi.Components.Widget ()
import Dashi.Style.Tokens (Appearance, Token (..))
import Dashi.Util (fromText)
import Data.Aeson qualified as Aeson
import Data.List qualified as List
import Miso
import Miso.Html.Property (aria_, tabindex_)
import Prelude

makePrisms ''Attribute

props :: [Attribute action] -> [(MisoString, Aeson.Value)]
props = toListOf $ traverse . _Property

findProp :: MisoString -> [Attribute action] -> Maybe Aeson.Value
findProp k = List.lookup k . props

isTrueProp :: MisoString -> Attribute action -> Bool
isTrueProp k (Property ((k ==) -> True) (Aeson.Bool True)) = True
isTrueProp k (Property ((k ==) -> True) (Aeson.String "true")) = True
isTrueProp _ _ = False

hasTrueProp :: MisoString -> [Attribute action] -> Bool
hasTrueProp = any . isTrueProp

isAriaBusy :: Attribute action -> Bool
isAriaBusy = isTrueProp "aria-busy"

hasAriaBusy :: [Attribute action] -> Bool
hasAriaBusy = hasTrueProp "aria-busy"

isRequired :: Attribute action -> Bool
isRequired = isTrueProp "required"

hasRequired :: [Attribute action] -> Bool
hasRequired = hasTrueProp "required"

tryGetId :: [Attribute action] -> Maybe MisoString
tryGetId =
    findProp "id" >=> \case
        Aeson.String s -> Just (fromText s)
        _ -> Nothing

ariaBusy_ :: Bool -> Attribute action
ariaBusy_ =
    aria_ "busy" . \case
        True -> "true"
        False -> "false"

ariaRole_ :: MisoString -> Attribute action
ariaRole_ = aria_ "role"

selectable_ :: Attribute action
selectable_ = tabindex_ "0"

unselectable_ :: Attribute action
unselectable_ = tabindex_ "-1"

appearance_ :: Appearance -> Attribute action
appearance_ = tokenAttr

autocomplete_ :: MisoString -> Attribute action
autocomplete_ = textProp "autocomplete"
