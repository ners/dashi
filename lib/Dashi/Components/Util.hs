{-# LANGUAGE TemplateHaskell #-}

module Dashi.Components.Util where

import Control.Monad ((>=>))
import Dashi.Prelude
import Dashi.Style.Tokens (Appearance, Token (..))
import Data.List qualified as List
import Miso.Html.Property (aria_, tabindex_)
import Miso.JSON qualified as JSON
import Miso.String qualified as MisoString

makePrisms ''Attribute

props :: [Attribute action] -> [(MisoString, JSON.Value)]
props = toListOf $ traverse . _Property

findProp :: MisoString -> [Attribute action] -> Maybe JSON.Value
findProp k = List.lookup k . props

isTrueProp :: MisoString -> Attribute action -> Bool
isTrueProp k (Property ((k ==) -> True) (JSON.Bool True)) = True
isTrueProp k (Property ((k ==) -> True) (JSON.String (MisoString.toLower -> "true"))) = True
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
        JSON.String s -> Just s
        _ -> Nothing

ariaBusy_ :: Bool -> Attribute action
ariaBusy_ =
    aria_ "busy" . \case
        True -> "true"
        False -> "false"

ariaInvalid_ :: Bool -> Attribute action
ariaInvalid_ =
    aria_ "invalid" . \case
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
