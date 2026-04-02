module Dashi.ColourScheme where

import Dashi.Prelude
import Dashi.Style.Colour qualified as Colour (Scheme)
import Dashi.Style.Colour qualified as Colour.Scheme

browserPreference :: IO Colour.Scheme
browserPreference =
    [js|
        return window.matchMedia("(prefers-color-scheme: dark)").matches
    |]
        <&> view (from Colour.Scheme.isDark)

get :: IO Colour.Scheme
get =
    [js|
        return document.querySelector('meta[name=color-scheme]')?.content || "";
    |]
        >>= either (const browserPreference) pure
        . fromMisoStringEither

set :: Colour.Scheme -> IO ()
set c =
    [js|
        function create() {
            const meta = document.createElement('meta');
            meta.setAttribute('name', 'color-scheme');
            document.getElementsByTagName('head')[0].appendChild(meta);
            return meta;
        }
        const header = document.querySelector('meta[name=color-scheme]') || create();
        header.setAttribute('content', ${c});
    |]
