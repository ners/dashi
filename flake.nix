{
  nixConfig = {
    extra-substituters = "https://cache.ners.ch/haskell";
    extra-trusted-public-keys = "haskell:WskuxROW5pPy83rt3ZXnff09gvnu80yovdeKDw5Gi3o=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghc-wasm-meta = {
      url = "github:haskell-wasm/ghc-wasm-meta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wasm = {
      url = "github:ners/nix-wasm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.ghc-wasm-meta.follows = "ghc-wasm-meta";
    };
    fluent-hs = {
      url = "github:ners/fluent-hs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    miso = {
      url = "github:haskell-miso/miso";
      flake = false;
    };
    phosphor-icons-web = {
      url = "github:phosphor-icons/web/v2.1.2";
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
      projects =
        with lib;
        genAttrs' (fileset.toList (fileset.fileFilter (file: file.hasExt "cabal") ./.)) (
          file: nameValuePair (removeSuffix ".cabal" (baseNameOf file)) (dirOf file)
        );
      pnames = lib.attrNames projects;
      pname = "dashi";
      haskell-overlay = pkgs: with pkgs.haskell.lib.compose; lib.composeManyExtensions [
        inputs.fluent-hs.overlays.haskell
        (hfinal: hprev: lib.mapAttrs (pname: dir: hfinal.callCabal2nix pname (sourceFilter dir) { }) projects)
        (hfinal: hprev: {
          buildDashiApp = import ./dashi/nix/buildDashiApp.nix {
            inherit inputs pkgs;
            haskellPackages = hfinal;
          };
        })
        (hfinal: hprev: {
          ${pname} = hfinal.buildDashiApp {
            name = pname;
            title = "Dashi";
            src = ./dashi;
            staticSrc = ./dashi/static;
            haskell-overlay = haskell-overlay pkgs;
          };
          feedback = hfinal.callCabal2nix "feedback"
            (pkgs.fetchFromGitHub
              {
                owner = "NorfairKing";
                repo = "feedback";
                rev = "5ec59759d4252f8d1c38c8b5e5580f543390a40e";
                hash = "sha256-kW0KtUZxF8xeccwCEfakS9PxrcVICVTuMH2QofYZYdI=";
              } + "/feedback")
            { };
          jsaddle-wasm = addBuildDepend hfinal.parser-regex hprev.jsaddle-wasm;
          miso = enableCabalFlag "template-haskell" (hfinal.callCabal2nix "miso" inputs.miso { });
        })
        (hfinal: hprev: lib.optionalAttrs (hprev.ghc.targetPrefix != "") {
          pretty-simple = hprev.pretty-simple.overrideAttrs (attrs: {
            postPatch = ''
              ${attrs.postPatch or ""}
              ${lib.getExe pkgs.perl} -0pe 's/executable .*(\n+  .*)+\n+//' -i pretty-simple.cabal
            '';
          });
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
        wasmGhc = "ghc914";
        vanillaGhc = "ghc912";
      in
      {
        packages.${system} = rec {
          default = pkgs.haskellPackages.${pname}.wasm.dist;
          wasmServer = pkgs.writeShellApplication {
            name = "${pname}-wasm-server";
            runtimeInputs = [ pkgs.http-server ];
            text = ''
              http-server "${default}" --brotli --gzip
            '';
          };
        };
        legacyPackages.${system} = pkgs // {
          inherit jsPkgs wasmPkgs;
        };
        devShells.${system}.default = pkgs.mkShell {
          inputsFrom = [
            (wasmPkgs.haskell.packages.${wasmGhc}.shellFor {
              packages = ps: [ ps.${pname} ];
              nativeBuildInputs = with wasmPkgs; [
                cabal-install
              ];
            })
            (pkgs.haskell.packages.${vanillaGhc}.shellFor {
              packages = ps: map (pname: ps.${pname}) pnames;
              nativeBuildInputs = with pkgs; [
                cabal-install
                fourmolu
                ghcid
                haskell.packages.${vanillaGhc}.haskell-language-server
                haskellPackages.cabal-gild
                haskellPackages.feedback
                http-server
                nixpkgs-fmt
                nodejs
                treefmt
              ];
            })
          ];
        };
        formatter.${system} = pkgs.treefmt;
      });
}
