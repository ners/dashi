{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghc-wasm-meta = {
      url = "gitlab:ners/ghc-wasm-meta/fix-nix-hostPlatform?host=gitlab.haskell.org";
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
      browser_wasi_shim = pkgs: pkgs.buildNpmPackage {
        pname = "browser_wasi_shim";
        version = "0.4.2";
        src = pkgs.fetchFromGitHub {
          owner = "haskell-wasm";
          repo = "browser_wasi_shim";
          rev = "fce68df4ad2bc9cfe6581a234587a76981882186";
          hash = "sha256-FFBG5VPFvONBz+eUD/YUR3SSy8gfAsuWB9Avi8S9yqQ=";
        };
        npmDepsHash = "sha256-ErxU2EA+Enh5Bpbk3rsTrgeQnMktLjv9eNE0h5phntY=";
        meta = {
          description = "A pure javascript shim for WASI";
          homepage = "https://github.com/haskell-wasm/browser_wasi_shim";
          license = with lib.licenses; [ asl20 mit ];
          maintainers = with lib.maintainers; [ ners ];
        };
      };
      favicon = pkgs: pkgs.runCommand "favicon.ico"
        {
          nativeBuildInputs = with pkgs; [
            imagemagick
            librsvg
          ];
        } ''
        tmpPng="$(mktemp --suffix=.png)"
        rsvg-convert "${./static/icon.svg}" \
          --width 64 \
          --output "$tmpPng"
        convert "$tmpPng" -define icon:auto-resize=64,48,32,16 "$out"
        rm "$tmpPng"
      '';
      apple-touch-icon = pkgs: pkgs.runCommand "apple-touch-icon.png"
        {
          nativeBuildInputs = with pkgs; [
            librsvg
          ];
        } ''
        rsvg-convert "${./static/icon.svg}" \
          --background-color '#3457D5' \
          --width 180 \
          --output "$out"
      '';
      staticAssets = pkgs: pkgs.runCommand "static" { } ''
        cp -r "${./static}" "$out"
        cd "$out"
        chmod -R +w .

        cp "${inputs.mdi-webfont}"/*.woff2 .
        cp "${favicon pkgs}" favicon.ico
        cp "${apple-touch-icon pkgs}" apple-touch-icon.png

        mkdir browser_wasi_shim
        cp -r "${browser_wasi_shim pkgs}"/lib/node_modules/*/browser_wasi_shim/dist/*.js browser_wasi_shim
      '';
      isWasmPkgs = haskellPackages: haskellPackages.ghc.targetPrefix == "wasm32-wasi-";
      haskell-overlay = pkgs: with pkgs.haskell.lib.compose; lib.composeManyExtensions [
        inputs.fluent-hs.overlays.haskell
        (inputs.web-font-mdi.overlays.haskell pkgs.haskell.lib)
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
        (hfinal: hprev: lib.optionalAttrs (isWasmPkgs hprev) {
          ${pname} = (appendBuildFlag "--ghc-options=-DWASM" hprev.${pname}).overrideAttrs (attrs:  {
            nativeBuildInputs = with pkgs; [
              binaryen
              nodejs
              wasm-tools
            ] ++ attrs.nativeBuildInputs or [ ];
            postInstall = (attrs.postInstall or "") + ''
              cd "$out"
              cp -r "${staticAssets pkgs}" static
              chmod -R +w static
              mv bin/*.wasm static/app.wasm
              rmdir bin
              cd static
              "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
              # hold @MagicRB accountable for this crime
              sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js
              wasm-opt -all -O2 app.wasm -o app.wasm
              wasm-tools strip -o app.wasm app.wasm
              sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html index.js
              cd ..
              mv static/index.html static/favicon.ico static/apple-touch-icon.png .
            '';
          });
        })
        (hfinal: hprev: lib.optionalAttrs (isWasmPkgs hprev) {
          zlib = addBuildDepend hprev.zlib-clib hprev.zlib;
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
        pkgs = pkgs' // {
          haskellPackages = pkgs'.haskell.packages.ghc912.extend (haskell-overlay pkgs');
        };
        wasmPkgs' = inputs.nix-wasm.legacyPackages.${system};
        wasmPkgs = wasmPkgs' // {
          haskellPackages = wasmPkgs'.haskellPackages.extend (haskell-overlay pkgs');
        };
        packages = ps: [ ps.${pname} ];
      in
      {
        packages.${system} = {
          default = pkgs.haskellPackages.${pname};
          wasm = wasmPkgs.haskellPackages.${pname}.overrideAttrs (attrs: {
            postFixup = ''
              ${attrs.postFixup or ""}
              rm -rf lib nix-support share
            '';
          });
          wasmServer = pkgs.writeShellApplication {
            name = "${pname}-wasm-server";
            runtimeInputs = with pkgs; [ http-server ];
            text = ''
              http-server ${wasmPkgs.haskellPackages.${pname}}
            '';
          };
        };
        legacyPackages.${system} = {
          inherit (pkgs) haskellPackages;
          inherit wasmPkgs;
          browser_wasi_shim = browser_wasi_shim pkgs;
        };
        devShells.${system} = {
          default = pkgs.haskellPackages.shellFor {
            inherit packages;
            nativeBuildInputs = with pkgs.haskellPackages; [
              cabal-install
              ghcid
              haskell-language-server
              pointfree-fancy
            ];
            shellHook = ''
              find static -type l -delete
              ln -s "${staticAssets pkgs}"/* static
              ln -fs static/index.html static/favicon.ico static/apple-touch-icon.png .
            '';
          };
          wasm = wasmPkgs.haskellPackages.shellFor {
            inherit packages;
            nativeBuildInputs = with wasmPkgs; [
              cabal-install
            ];
          };
        };
      });
}
