{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghc-wasm-meta = {
      url = "gitlab:haskell-wasm/ghc-wasm-meta?host=gitlab.haskell.org";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wasm = {
      url = "github:ners/nix-wasm";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
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
          identicon-style-squares = dontCheck (doJailbreak hprev.identicon-style-squares);
          jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
          miso = hfinal.callCabal2nix "miso" inputs.miso { };
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
          ${pname} = appendBuildFlag "--ghc-options=-DGHCJS_BROWSER" hprev.${pname} // {
            inherit (hprev.${pname}) staticAssets;
            dist = pkgs.runCommand "${pname}-js-dist"
              {
                nativeBuildInputs = with pkgs; [
                  closurecompiler
                ];
              }
              ''
                function compare() {
                  echo "$1: $(numfmt --to=si --suffix=B $2) -> $(numfmt --to=si --suffix=B $3) ($(( $3 * 100 / $2 - 100 ))%)"
                }
                mkdir -p "$out"
                cd "$out"
                cp -r "${hfinal.${pname}.staticAssets}" static
                chmod -R +w static
                pushd "${hfinal.${pname}}/bin/${pname}.jsexe/"
                mainjs="$out/static/main.js"
                closure-compiler \
                  --js=all.js \
                  --js_output_file="$mainjs" \
                  --jscomp_off=checkVars \
                  --externs all.externs.js \
                  --compilation_level ADVANCED_OPTIMIZATIONS \
                  --language_in UNSTABLE
                compare "main.js" $(cat all.js | wc -c) $(gzip -c all.js | wc -c)
                compare "main.js.gz" $(cat "$mainjs" | wc -c) $(gzip -c "$mainjs" | wc -c)
                popd
                cd static
                rm -fr browser_wasi_shim
                sed -i "s/\?v=0/\?v=$(md5sum main.js | cut -d' ' -f1)/" index.html
                cd ..
                mv static/{index.html,404.html,favicon.ico,apple-touch-icon.png} .
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
                    eval "$*"
                    size2="$(cat $f2 | wc -c)"
                    gzip2="$(gzip -c $f2 | wc -c)"
                    compare $f2 $size1 $size2
                    compare $f2.gz $gzip1 $gzip2
                }
                mkdir -p "$out"
                cd "$out"
                cp -r "${hfinal.${pname}.staticAssets}" static
                cd static
                chmod -R +w .
                cp "${hfinal.${pname}}/bin/${pname}.wasm" app.wasm
                chmod +w app.wasm
                "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
                # hold @MagicRB accountable for this crime
                sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js

                compress app.wasm{,} "wasm-opt -all -O2 -o app.wasm{,} ; wasm-tools strip -o app.wasm{,}"
                sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html main.js

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
                mv static/{index.html,404.html,favicon.ico,apple-touch-icon.png} .
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
          csso = prev.buildNpmPackage rec {
            pname = "csso";
            version = "4.0.2";
            src = prev.fetchFromGitHub {
              owner = "css";
              repo = "csso-cli";
              tag = "v${version}";
              hash = "sha256-mP3Q+7JlgIfPLZsCtYSpTBdV4+tT5qiEeP6fB87Wxw8=";
            };
            npmDepsHash = "sha256-IKy4o/tcNo0Hy49aTKAoHhfsR3xUNFYeBuvSoZXh0UI=";
            dontNpmBuild = true;
          };
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
        hps = with lib; foldlAttrs
          (acc: name: hp':
            let
              hp = tryEval hp';
              version = getVersion hp.value.ghc;
              majorMinor = versions.majorMinor version;
              ghcName = "ghc${replaceStrings ["."] [""] majorMinor}";
            in
            if hp.value ? ghc && ! acc ? ${ghcName} && versionAtLeast version "9.4" && versionOlder version "9.13"
            then acc // { ${ghcName} = hp.value; }
            else acc
          )
          { default = pkgs.haskellPackages; }
          pkgs.haskell.packages;
        pkg = pkgs: pkgs.haskell.packages.ghc912.${pname};
        dist = pkgs: (pkg pkgs).dist;
      in
      {
        packages.${system} = {
          default = pkgs.linkFarmFromDrvs pname ([ (pkg pkgs) ] ++ map dist [ jsPkgs wasmPkgs ]);
          jsServer = pkgs.writeShellApplication {
            name = "${pname}-js-server";
            runtimeInputs = with pkgs; [ http-server ];
            text = "http-server ${dist jsPkgs}";
          };
          wasmServer = pkgs.writeShellApplication {
            name = "${pname}-wasm-server";
            runtimeInputs = with pkgs; [ http-server ];
            text = "http-server ${dist wasmPkgs}";
          };
        };
        legacyPackages.${system} = pkgs // {
          inherit jsPkgs wasmPkgs;
        };
        devShells.${system} =
          foreach hps (ghcName: hp: {
            ${ghcName} = hp.shellFor {
              inherit packages;
              nativeBuildInputs = with pkgs.haskellPackages; [
                cabal-install
                ghcid
                hp.haskell-language-server
                pointfree-fancy
              ];
              shellHook = ''
                find static -type l -delete
                ln -s "${hp.${pname}.staticAssets}"/* static
                ln -fs static/index.html static/favicon.ico static/apple-touch-icon.png .
              '';
            };
          } // {
            wasm = wasmPkgs.haskellPackages.shellFor {
              inherit packages;
              nativeBuildInputs = with wasmPkgs; [
                cabal-install
              ];
            };
          });
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
