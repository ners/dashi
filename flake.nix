{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:ners/nixpkgs/haskell";
    nix-wasm = {
      url = "github:ners/nix-wasm";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      browser_wasi_shim = pkgs: pkgs.buildNpmPackage (finalAttrs: {
        pname = "browser_wasi_shim";
        version = "0.4.2";
        src = pkgs.fetchFromGitHub {
          owner = "haskell-wasm";
          repo = "browser_wasi_shim";
          rev = "381277af3cf7d49b90cad2d5b23a2b55cd36f874";
          hash = "sha256-6oj2H2eB8KaqFcp+9VU9iXFnsuZ/ljDp9724xBeNUM8=";
        };
        npmDepsHash = "sha256-2EXpcUxuhP/FHtALb3j0zIQWRfeII1r495ydm+lAp3Y=";
        meta = {
          description = "A pure javascript shim for WASI";
          homepage = "https://github.com/haskell-wasm/browser_wasi_shim";
          license = with lib.licenses; [ asl20 mit ];
          maintainers = with lib.maintainers; [ ners ];
        };
      });
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
      staticAssets = pkgs: pkgs.runCommand "static" { } ''
        mkdir "$out"
        cd "$out"
        cp "${inputs.mdi-webfont}"/*.woff2 .
        cp "${favicon pkgs}" favicon.ico

        mkdir browser_wasi_shim
        cp -r "${browser_wasi_shim pkgs}"/lib/node_modules/*/browser_wasi_shim/dist/*.js browser_wasi_shim
      '';
      haskell-overlay = pkgs: lib.composeManyExtensions [
        inputs.fluent-hs.overlays.haskell
        (inputs.web-font-mdi.overlays.haskell pkgs.haskell.lib)
        (hfinal: hprev: with pkgs.haskell.lib.compose; {
          ${pname} = (hfinal.callCabal2nix pname (sourceFilter ./.) { }).overrideAttrs (attrs: {
            nativeBuildInputs = with pkgs; [
              binaryen
              nodejs
              wasm-tools
            ] ++ attrs.nativeBuildInputs or [ ];
            postInstall = (attrs.postInstall or "") + lib.optionalString (hfinal.ghc.targetPrefix == "wasm32-wasi-") ''
              cd "$out"
              mv bin/*.wasm app.wasm
              rmdir bin
              "$(wasm32-wasi-ghc --print-libdir)"/post-link.mjs --input app.wasm --output ghc_wasm_jsffi.js
              # hold @MagicRB accountable for this crime
              sed -i 's/var runBatch = /var initialSyncDepth = 0; &/' ghc_wasm_jsffi.js
              wasm-opt -all -O2 app.wasm -o app.wasm
              wasm-tools strip -o app.wasm app.wasm
              cp -r "${./static}"/* .
              ln -s "${staticAssets pkgs}"/* .
              sed -i "s/\?v=0/\?v=$(md5sum app.wasm | cut -d' ' -f1)/" index.html index.js
            '';
          });
          miso = hfinal.callCabal2nix "miso" inputs.miso { };
          jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
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
          haskellPackages = pkgs'.haskellPackages.extend (haskell-overlay pkgs');
        };
        wasmPkgs' = inputs.nix-wasm.legacyPackages.${system};
        wasmPkgs = wasmPkgs' // {
          haskellPackages = wasmPkgs'.haskellPackages.extend (haskell-overlay pkgs');
        };
      in
      {
        packages.${system} = {
          default = pkgs.haskellPackages.${pname};
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
        };
        devShells.${system} = {
          default = pkgs.haskellPackages.shellFor {
            packages = ps: [ ps.${pname} ];
            nativeBuildInputs = with pkgs.haskellPackages; [
              cabal-install
              ghcid
              haskell-language-server
            ];
            shellHook = ''
              ln -fs "${staticAssets pkgs}"/* static
            '';
          };
          wasm = wasmPkgs.haskellPackages.shellFor {
            packages = ps: [ ps.${pname} ];
            nativeBuildInputs = with wasmPkgs; [
              cabal-install
            ];
          };
        };
      });
}
