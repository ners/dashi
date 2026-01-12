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
      isJsPkgs = haskellPackages: haskellPackages.ghc.targetPrefix == "javascript-unknown-ghcjs-";
      isVanillaPkgs = haskellPackages: haskellPackages.ghc.targetPrefix == "";
      isWasmPkgs = haskellPackages: haskellPackages.ghc.targetPrefix == "wasm32-wasi-";
      pname = "dashi";
      haskell-overlay = pkgs:
        with pkgs.haskell.lib.compose;
        let
          staticAssets = pkgs.callPackage ./static-assets.nix { inherit inputs; };
        in
        lib.composeManyExtensions [
          inputs.fluent-hs.overlays.haskell
          (inputs.web-font-mdi.overlays.haskell pkgs)
          (hfinal: hprev: {
            ${pname} = hfinal.callCabal2nix pname (sourceFilter ./.) { };
            identicon-style-squares = dontCheck (doJailbreak hprev.identicon-style-squares);
            jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
            miso = hfinal.callCabal2nix "miso" inputs.miso { };
            miso-diagrams = hfinal.callCabal2nix "miso-diagrams" inputs.miso-diagrams { };
            plots = doJailbreak (unmarkBroken hprev.plots);
            pointfree-fancy = doJailbreak (unmarkBroken hprev.pointfree-fancy);
            polyvariadic = doJailbreak (unmarkBroken hprev.polyvariadic);
            sandwich = dontCheck hprev.sandwich;
          })
          (hfinal: hprev: lib.optionalAttrs (isVanillaPkgs hprev) {
            ${pname} = appendBuildFlag "--ghc-options=-DVANILLA" hprev.${pname} // {
              dist =
                pkgs.runCommand "${pname}-dist"
                  { }
                  ''
                    mkdir -p "$out"
                    cd "$out"
                    cp -r "${hfinal.${pname}}/bin" bin
                  '';
            };
          })
          (hfinal: hprev: lib.optionalAttrs (isJsPkgs hprev) {
            ${pname} = appendBuildFlag "--ghc-options=-DGHCJS_BROWSER" hprev.${pname} // {
              dist =
                pkgs.runCommand "${pname}-js-dist"
                  {
                    nativeBuildInputs = with pkgs; [
                      closurecompiler
                    ];
                  }
                  ''
                    mkdir -p "$out"
                    cd "$out"
                    cp -r "${staticAssets}" static
                    chmod -R +w static
                    pushd "${hfinal.${pname}}/bin/${pname}.jsexe/"
                    closure-compiler \
                      --js=all.js \
                      --js_output_file="$out/static/index.js" \
                      --jscomp_off=checkVars \
                      --externs all.externs.js \
                      --compilation_level ADVANCED_OPTIMIZATIONS \
                      --language_in UNSTABLE
                    popd
                    cd static
                    rm -fr browser_wasi_shim
                    sed -i "s/\?v=0/\?v=$(md5sum index.js | cut -d' ' -f1)/" index.html
                    cd ..
                    mv static/{index.html,404.html,favicon.ico,apple-touch-icon.png} .
                  '';
            };
          })
          (hfinal: hprev: lib.optionalAttrs (isWasmPkgs hprev) {
            ${pname} = appendBuildFlag "--ghc-options=-DWASM" hprev.${pname} // {
              dist =
                pkgs.runCommand "${pname}-wasm-dist"
                  {
                    nativeBuildInputs = with pkgs; [
                      hfinal.ghc
                      binaryen
                      nodejs
                      wasm-tools
                    ];
                  }
                  ''
                    mkdir -p "$out"
                    cd "$out"
                    cp -r "${staticAssets}" static
                    chmod +w static
                    cp "${hfinal.${pname}}/bin"/*.wasm static/app.wasm
                    chmod -R +w static
                    cd static
                    "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
                    # hold @MagicRB accountable for this crime
                    sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js
                    wasm-opt -all -O2 app.wasm -o app.wasm
                    wasm-tools strip -o app.wasm app.wasm
                    sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html index.js
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
              (haskell-overlay prev)
            ];
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
        dist = pkgs: pkgs.haskell.packages.ghc912.${pname}.dist;
        staticAssets = pkgs.callPackage ./static-assets.nix { inherit inputs; };
      in
      {
        packages.${system} = {
          inherit staticAssets;
          default = pkgs.linkFarmFromDrvs pname (map dist [ pkgs jsPkgs wasmPkgs ]);
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
          browser_wasi_shim = browser_wasi_shim pkgs;
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
                ln -s "${staticAssets}"/* static
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
      });
}
