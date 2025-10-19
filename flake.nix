{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fluent-hs = {
      url = "github:ners/fluent-hs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghc-wasm-meta = {
      url = "gitlab:haskell-wasm/ghc-wasm-meta?host=gitlab.haskell.org";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    miso = {
      url = "github:dmjio/miso";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wasm = {
      url = "github:ners/nix-wasm";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
      inputs.nixpkgs.follows = "nixpkgs";
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
    ghc-source-gen = {
      url = "github:google/ghc-source-gen";
      flake = false;
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
    in
    foreach inputs.nixpkgs.legacyPackages (system: pkgs:
      let
        browser_wasi_shim = pkgs.buildNpmPackage (finalAttrs: {
          pname = "browser_wasi_shim";
          version = "0.4.2";
          src = pkgs.fetchFromGitHub {
            owner = "bjorn3";
            repo = "browser_wasi_shim";
            tag = "v${finalAttrs.version}";
            hash = "sha256-okP2bT4rcqtwTk7eOdyC+DqoLACTS9srANgSEkjb06A=";
          };
          npmDepsHash = "sha256-5CUnps7UyX9U7ZRRaUy0t7lpXoOhFR8n7AEPTD0npF0=";
          meta = {
            description = "A pure javascript shim for WASI";
            homepage = "https://github.com/bjorn3/browser_wasi_shim";
            license = with lib.licenses; [ asl20 mit ];
            maintainers = with lib.maintainers; [ ners ];
          };
        });
        favicon = pkgs.runCommand "favicon.ico"
          {
            nativeBuildInputs = with pkgs; [
              imagemagick
              inkscape
            ];
          } ''
          tmpPng="$(mktemp --suffix=.png)"
          inkscape "${./.}/static/icon.svg" \
            --export-width=64 \
            --export-filename="$tmpPng"
          convert "$tmpPng" -define icon:auto-resize=64,48,32,16 "$out"
          rm "$tmpPng"
        '';
        staticAssets = pkgs.runCommand "static" { } ''
          mkdir "$out"
          cd "$out"
          cp "${inputs.mdi-webfont}"/*.woff2 .
          cp "${favicon}" favicon.ico

          mkdir browser_wasi_shim
          cp -r "${browser_wasi_shim}/lib/node_modules/@bjorn3/browser_wasi_shim/dist"/*.js browser_wasi_shim
        '';
        haskell-overlay = lib.composeManyExtensions [
          inputs.fluent-hs.overlays.haskell
          (inputs.web-font-mdi.overlays.haskell pkgs.haskell.lib)
          (hfinal: hprev: with pkgs.haskell.lib.compose; {
            dashi = (hfinal.callCabal2nix "dashi" (sourceFilter ./.) { }).overrideAttrs (attrs: {
              nativeBuildInputs = with pkgs; [
                binaryen
                nodejs
                wasm-tools
              ] ++ attrs.nativeBuildInputs or [ ];
              postInstall = ''
                ${attrs.postInstall or ""}
                cd "$out"
                mv bin/*.wasm app.wasm
                rmdir bin
                $(wasm32-wasi-ghc --print-libdir)/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
                # hold @MagicRB accountable for this crime
                sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js
                wasm-opt -all -O2 app.wasm -o app.wasm
                wasm-tools strip -o app.wasm app.wasm
                cp -r "${./.}"/static/* .
                ln -s ${staticAssets}/* .
                sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html index.js
              '';
            });
            miso = hfinal.callCabal2nix "miso" inputs.miso { };
            ghc-source-gen = hfinal.callCabal2nix "ghc-source-gen" inputs.ghc-source-gen { };
            jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
          })
        ];
        extend = hp: hp.extend haskell-overlay;
        wasmPackages = extend inputs.nix-wasm.legacyPackages.${system}.haskellPackages;
        haskellPackages = extend pkgs.haskellPackages;
      in
      {
        packages.${system}.default = pkgs.writeShellApplication {
          name = "dashi-app";
          runtimeInputs = with pkgs; [ http-server ];
          text = ''
            http-server ${wasmPackages.dashi}
          '';
        };
        legacyPackages.${system} = {
          inherit haskellPackages wasmPackages browser_wasi_shim favicon;
        };
        devShells.${system} = {
          default = haskellPackages.shellFor {
            packages = ps: [ ps.dashi ];
            nativeBuildInputs = with pkgs.haskellPackages; [
              cabal-install
              haskell-language-server
            ];
            env.NIXPKGS_ALLOW_BROKEN = "1";
            shellHook = ''
              ln -s ${staticAssets}/* static
            '';
          };
        };
      });
}
