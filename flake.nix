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
    miso = {
      url = "github:dmjio/miso";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
      inputs.nixpkgs.follows = "nixpkgs";
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
        extend = hp: hp.extend (hfinal: hprev: with pkgs.haskell.lib.compose; {
          dashi = (hfinal.callCabal2nix "dashi" (sourceFilter ./.) { }).overrideAttrs (attrs: {
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
              cp -r "${./.}"/static/* "$out"
              sed -i "s/\?v=0/\?v=$(md5sum "$wasm" | cut -d' ' -f1)/" index.html index.js
            '';
          });
          miso = hfinal.callCabal2nix "miso" inputs.miso { };
          jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
        });
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
          inherit haskellPackages wasmPackages;
        };
        devShells.${system} = {
          default = haskellPackages.shellFor {
            packages = ps: [ ps.dashi ];
            nativeBuildInputs = with pkgs.haskellPackages; [
              cabal-install
              haskell-language-server
            ];
          };
        };
      });
}
