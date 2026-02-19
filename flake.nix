{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-wasm = {
      url = "github:ners/nix-wasm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fluent-hs = {
      url = "github:ners/fluent-hs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    miso = {
      url = "github:haskell-miso/miso";
      flake = false;
    };
    miso-diagrams = {
      url = "github:haskell-miso/miso-diagrams";
      flake = false;
    };
    mdi = {
      url = "github:Templarian/MaterialDesign";
      flake = false;
    };
    mdi-webfont = {
      url = "github:Templarian/MaterialDesign-Webfont?dir=fonts";
      flake = false;
    };
    web-font-mdi = {
      url = "github:ners/web-font-mdi";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.mdi.follows = "mdi";
    };
  };

  outputs = inputs:
    with builtins;
    let
      inherit (inputs.nixpkgs) lib;
      foreach = xs: f: with lib; foldr recursiveUpdate { } (
        if isList xs then map f xs
        else if isAttrs xs then mapAttrsToList f xs
        else throw "foreach: expected list or attrset but got ${typeOf xs}"
      );
      sourceFilter = root: with lib.fileset; toSource {
        inherit root;
        fileset = fileFilter
          (file: any file.hasExt [ "cabal" "hs" "md" ])
          root;
      };
      pname = "dashi";
      haskell-overlay = pkgs: with pkgs.haskell.lib.compose; lib.composeManyExtensions [
        inputs.fluent-hs.overlays.haskell
        (inputs.web-font-mdi.overlays.haskell pkgs)
        (hfinal: hprev: {
          ${pname} = hfinal.callCabal2nix pname (sourceFilter ./.) { } // {
            staticAssets = pkgs.callPackage ./static-assets.nix { inherit inputs; };
          };
          jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
          miso = enableCabalFlag "template-haskell" (hfinal.callCabal2nix "miso" inputs.miso { });
          miso-diagrams = hfinal.callCabal2nix "miso-diagrams" inputs.miso-diagrams { };
          plots = doJailbreak (unmarkBroken hprev.plots);
          pointfree-fancy = doJailbreak (unmarkBroken hprev.pointfree-fancy);
          polyvariadic = doJailbreak (unmarkBroken hprev.polyvariadic);
          sandwich = dontCheck hprev.sandwich;
        })
        (hfinal: hprev: lib.optionalAttrs (hprev.ghc.targetPrefix == "") {
          ${pname} = appendBuildFlag "--ghc-options=-DVANILLA" hprev.${pname} // {
            inherit (hprev.${pname}) staticAssets;
          };
        })
        (hfinal: hprev: lib.optionalAttrs (hprev.ghc.targetPrefix == "javascript-unknown-ghcjs-") {
          mkDerivation = args: hprev.mkDerivation (args // {
            enableExternalInterpreter = false;
          });
          ${pname} = appendBuildFlag "--ghc-options=-DGHCJS_BROWSER" hprev.${pname} // {
            inherit (hprev.${pname}) staticAssets;
            dist = pkgs.runCommand "${pname}-js-dist"
              {
                nativeBuildInputs = with pkgs; [
                  webpack-cli
                ];
              }
              ''
                function compare() {
                  echo "$1: $(numfmt --to=si --suffix=B $2) -> $(numfmt --to=si --suffix=B $3) ($(( $3 * 100 / $2 - 100 ))%)"
                }
                mkdir -p "$out"
                cd "$out"
                cp -r "${hfinal.${pname}.staticAssets}"/* .
                chmod -R +w .
                pushd "${hfinal.${pname}}/bin/${pname}.jsexe/"
                webpack --config "${pkgs.writeText "webpack.config.js" /*javascript*/ ''
                  module.exports = {
                    mode: "production",
                    optimization: {
                      usedExports: true,
                      chunkIds: "total-size",
                    },
                    resolve: {
                      fallback: {
                        fs: false,
                        os: false,
                        path: false,
                        "ghcjs-profiling": false,
                        "child_process": false,
                      },
                    },
                  };
                ''}" --output-path "$out" --entry ./all.js
                mainjs="$out/static/main.js"
                mv "$out/main.js" "$mainjs"
                compare "main.js" $(cat all.js | wc -c) $(cat "$mainjs" | wc -c)
                compare "main.js.gz" $(gzip -c all.js | wc -c) $(gzip -c "$mainjs" | wc -c)
                popd
                rm -fr static/browser_wasi_shim
                sed -i "s/\?v=0/\?v=$(md5sum main.js | cut -d' ' -f1)/" index.html
              '';
          };
        })
        (hfinal: hprev: lib.optionalAttrs (hprev.ghc.targetPrefix == "wasm32-wasi-") {
          ${pname} = appendBuildFlag "--ghc-options=-DWASM" hprev.${pname} // {
            inherit (hprev.${pname}) staticAssets;
            dist = pkgs.runCommand "${pname}-wasm-dist"
              {
                nativeBuildInputs = with pkgs; [
                  binaryen
                  brotli
                  hfinal.ghc
                  nodejs
                  wasm-tools
                  webpack-cli
                ];
              }
              ''
                function compare() {
                  echo "$1: $(numfmt --to=si --suffix=B $2) -> $(numfmt --to=si --suffix=B $3) ($(( $3 * 100 / $2 - 100 ))%)"
                }
                function compress() {
                    f1="$1"
                    shift
                    f2="$1"
                    shift
                    size1="$(cat $f1 | wc -c)"
                    gzip1="$(gzip -c $f1 | wc -c)"
                    brotli1="$(brotli -c $f1 | wc -c)" || true
                    eval "$*"
                    size2="$(cat $f2 | wc -c)"
                    gzip2="$(gzip -c $f2 | wc -c)"
                    brotli2="$(brotli -c $f2 | wc -c)" || true
                    compare $f2 $size1 $size2
                    compare $f2.gz $gzip1 $gzip2
                    compare $f2.br $brotli1 $brotli2
                }
                mkdir -p "$out"
                cd "$out"
                cp -r "${hfinal.${pname}.staticAssets}"/* .
                chmod -R +w .
                cd static
                cp "${hfinal.${pname}}/bin/${pname}.wasm" app.wasm
                chmod +w app.wasm
                "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
                # hold @MagicRB accountable for this crime
                sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js

                compress app.wasm{,} "wasm-opt -all -O2 -o app.wasm{,} ; wasm-tools strip -o app.wasm{,}"

                substituteInPlace ghc_wasm_jsffi.js --replace-fail "node:timers" timers
                entries="./main.js ./ghc_wasm_jsffi.js ./browser_wasi_shim/*.js"
                compress "$entries" main.js webpack --config "${pkgs.writeText "webpack.config.js" /*javascript*/ ''
                  module.exports = {
                    resolve: {
                      fallback: {
                        timers: false, // do not include a polyfill for node:timers
                      },
                    },
                  };
                ''}" --mode production --output-path . --entry $entries
                rm -fr ghc_wasm_jsffi.js browser_wasi_shim
                cd ..
                sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html static/main.js
              '';
          };
        })
      ];
      overlay = lib.composeManyExtensions [
        (final: prev: {
          haskell = prev.haskell // {
            packageOverrides = lib.composeManyExtensions [
              prev.haskell.packageOverrides
              (haskell-overlay final)
            ];
          };
          inherit (final.haskellPackages) dashi;
        })
      ];
      extendHaskellPackages = nativePkgs: pkgs:
        let extend = ps: ps.extend (haskell-overlay nativePkgs); in pkgs // {
          haskellPackages = extend pkgs.haskellPackages;
          haskell = pkgs.haskell // { packages = lib.mapAttrs (_: extend) pkgs.haskell.packages; };
        };
    in
    {
      overlays = {
        default = overlay;
        haskell = haskell-overlay;
      };
    }
    //
    foreach inputs.nixpkgs.legacyPackages (system: pkgs':
      let
        pkgs = pkgs'.extend overlay;
        jsPkgs = extendHaskellPackages pkgs pkgs.pkgsCross.ghcjs;
        wasmPkgs = extendHaskellPackages pkgs inputs.nix-wasm.legacyPackages.${system};
        packages = ps: [ ps.${pname} ];
        ghc = "ghc912";
        caddyConfig = {
          apps.http = {
            http_port = 8080;
            servers.srv0 = {
              listen = [ ":8080" ];
              routes = [
                {
                  match = [{ host = [ "localhost" "127.0.0.1" ]; }];
                  handle = [
                    {
                      handler = "subroute";
                      routes = [{
                        handle = [
                          {
                            handler = "vars";
                            root = wasmPkgs.haskellPackages.${pname}.staticAssets;
                          }
                          {
                            handler = "encode";
                            encodings = { gzip = { }; zstd = { }; };
                          }
                          { handler = "file_server"; }
                        ];
                      }];
                      errors.routes = [
                        {
                          handle = [
                            {
                              handler = "encode";
                              encodings = { gzip = { }; zstd = { }; };
                            }
                            {
                              handler = "reverse_proxy";
                              upstreams = [{ dial = "localhost:8081"; }];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  terminal = true;
                }
              ];
            };
          };
        };
      in
      {
        packages.${system} = rec {
          default = wasmPkgs.haskell.packages.${ghc}.${pname}.dist;
          wasmServer = pkgs.writeShellApplication {
            name = "${pname}-wasm-server";
            runtimeInputs = [ pkgs.http-server ];
            text = ''
              http-server "${default}" --brotli --gzip
            '';
          };
          wasmDevServer = pkgs.writeShellApplication {
            name = "${pname}-wasm-dev-server";
            runtimeInputs = [
              pkgs.caddy
              wasmPkgs.cabal-install
            ];
            text = ''
              caddy run --config "${(pkgs.formats.json {}).generate "caddy.json" caddyConfig}" &
              wasm32-wasi-cabal repl exe:${pname} -finteractive --repl-options='-fghci-browser -fghci-browser-port=8081'
              kill %%
            '';
          };
        };
        legacyPackages.${system} = pkgs // {
          inherit jsPkgs wasmPkgs;
        };
        devShells.${system}.default = pkgs.mkShell {
          inputsFrom = [
            (wasmPkgs.haskellPackages.shellFor {
              inherit packages;
              nativeBuildInputs = with wasmPkgs; [
                cabal-install
              ];
            })
            (pkgs.haskell.packages.${ghc}.shellFor {
              inherit packages;
              nativeBuildInputs = with pkgs; [
                cabal-install
                haskell.packages.${ghc}.haskell-language-server
              ];
            })
          ];
        };
        formatter.${system} = pkgs.writeShellApplication {
          name = "formatter";
          runtimeInputs = with pkgs; with haskellPackages; [
            cabal-gild
            fd
            fourmolu
            nixpkgs-fmt
          ];
          text = ''
            fd --extension=nix -X nixpkgs-fmt
            fd --extension=hs -X fourmolu -i
            fd --extension=cabal -x cabal-gild --io
          '';
        };
      });
}
