{ inputs
, pkgs
, haskellPackages
}:

{ name
, title
, src
, args ? { }
, staticSrc
, haskell-overlay ? _: _: { }
}:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  wasmPkgs = inputs.nix-wasm.legacyPackages.${system};
  overlay = lib.composeManyExtensions [
    haskell-overlay
    (import
      ./haskell-overlay.nix
      { inherit inputs pkgs haskellPackages; }
      { inherit name title src args staticSrc; }
    )
  ];
  getPkg = ps: (ps.extend overlay).${name};
in
(getPkg haskellPackages) // {
  wasm = getPkg wasmPkgs.haskell.packages.ghc914;
}
