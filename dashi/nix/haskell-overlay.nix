{ inputs
, pkgs
, haskellPackages
}:

let
  inherit (pkgs) lib;
  overlay =
    name: title: src: staticSrc: args: hfinal: hprev:
    let
      inherit (pkgs) lib;
      isVanilla = hprev.ghc.targetPrefix == "";
      isWasm = hprev.ghc.targetPrefix == "wasm32-wasi-";
      ghcBuildFlag =
        if isVanilla then "VANILLA"
        else if isWasm then "WASM"
        else throw "unrecognised ghc.targetPrefix: ${hprev.ghc.targetPrefix}";
      staticAssets =
        import
          ./static-assets.nix
          { inherit inputs pkgs haskellPackages; }
          { inherit name title staticSrc; };
    in
    with pkgs.haskell.lib.compose;
    {
      ${name} = lib.foldr lib.recursiveUpdate { } [
        (appendBuildFlag "--ghc-options=-D${ghcBuildFlag}" (hfinal.callCabal2nix name src args))
        {
          inherit staticAssets;
          staticAssetsNoDashiCss = staticAssets.override { withDashiCss = false; };
        }
        (lib.optionalAttrs isWasm {
          dist = pkgs.runCommand "${name}-wasm-dist"
            {
              nativeBuildInputs = with pkgs; [
                binaryen
                hfinal.ghc
                nodejs
                wasm-tools
                webpack-cli
              ];
            }
            ''
              cp -r "${staticAssets}" "$out"
              cd "$out"
              chmod -R +w .
              cd static
              cp "${hprev.${name}}"/bin/${name}.wasm app.wasm
              chmod +w app.wasm
              "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
              # hold @MagicRB accountable for this crime
              sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js

              wasm-opt -all -O2 -o app.wasm{,}
              wasm-tools strip -o app.wasm{,}

              substituteInPlace ghc_wasm_jsffi.js --replace-fail "node:timers" timers
              webpack --config "${pkgs.writeText "webpack.config.js" /*javascript*/ ''
                module.exports = {
                  resolve: {
                    fallback: {
                      timers: false, // do not include a polyfill for node:timers
                    },
                  },
                };
              ''}" --mode production --output-path . --entry ./main.js ./ghc_wasm_jsffi.js ./browser_wasi_shim/*.js
              rm -fr ghc_wasm_jsffi.js browser_wasi_shim 280.js
              cd ..
              sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html static/main.js
            '';
        })
      ];
    };
in

{ name
, title
, src
, staticSrc
, args ? { }
}:

lib.composeManyExtensions [
  (
    if name == "dashi"
    then _: _: { }
    else overlay "dashi" "Dashi" ../. ../static { }
  )
  (overlay name title src staticSrc args)
]
