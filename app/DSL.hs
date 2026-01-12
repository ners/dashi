module DSL (module DSL, module Miso.DSL) where

import Dashi.Prelude hiding (head, (#))
import Miso.DSL
import Miso.Types

call' :: (ToArgs args, ToObject obj) => MisoString -> args -> obj -> IO JSVal
call' f a o = o # f $ a

document :: IO JSVal
document = jsg "document"

window :: IO JSVal
window = jsg "window"

createElement :: MisoString -> [(MisoString, MisoString)] -> IO JSVal
createElement tag attrs = do
    e <- call' "createElement" tag =<< document
    for_ attrs $ e # "setAttribute"
    pure e

appendChild :: JSVal -> JSVal -> IO JSVal
appendChild child parent = parent # "appendChild" $ child

getElementByTagName :: MisoString -> JSVal -> IO JSVal
getElementByTagName = call' "getElementByTagName"
