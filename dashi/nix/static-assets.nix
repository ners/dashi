{ inputs
, pkgs
, haskellPackages
}:

{ name
, title
, staticSrc
, withDashiCss ? true
}:

let
  inherit (pkgs) lib;
  browser_wasi_shim = pkgs.buildNpmPackage {
    pname = "browser_wasi_shim";
    version = "0.4.2";
    src = pkgs.fetchFromGitHub {
      owner = "haskell-wasm";
      repo = "browser_wasi_shim";
      rev = "2f86b49dce50916e2984029c535321e34b234229";
      hash = "sha256-tfq0gNw1wFMNALVAXzUg6CMRbvxNjM95bwp4Ncv4+W8=";
    };
    npmDepsHash = "sha256-mCrB6pYHdmd2xOoM66Kc/QRb1BLcfmEERA/YnnUPcYU=";
    installPhase = ''
      mv dist "$out"
    '';
    meta = {
      description = "A pure javascript shim for WASI";
      homepage = "https://github.com/haskell-wasm/browser_wasi_shim";
      license = with lib.licenses; [ asl20 mit ];
      maintainers = with lib.maintainers; [ ners ];
    };
  };
  dashi-css = pkgs.runCommand "dashi.css"
    {
      nativeBuildInputs = [
        haskellPackages.dashi
        pkgs.csso-cli
      ];
    }
    ''
      mkdir "$out"
      cd "$out"
      dashi-style > dashi.css
      csso --input dashi.css --output dashi.min.css
    '';
  phosphor = pkgs.runCommand "phosphor" { } ''
    mkdir "$out"
    cp '${inputs.phosphor-icons-web}'/src/*/*.{woff{,2},ttf} "$out"
  '';
in
pkgs.runCommand "${name}-static-assets"
{
  env = {
    inherit title;
  };
  nativeBuildInputs = with pkgs; [
    imagemagick
    librsvg
  ];
} ''
  mkdir -p "$out"
  cd "$out"
  mkdir static
  cd static
  ${lib.optionalString (name != "dashi") ''
    cp '${../static/main.js}' main.js
    cp '${../static/index.html}' index.html
  ''}
  ${lib.optionalString withDashiCss ''
    cp '${dashi-css}'/* .
  ''}
  for f in '${staticSrc}'/*; do
    cp -fr "$f" "$(basename "$f")"
  done
  cp -r '${phosphor}' phosphor
  cp -r '${browser_wasi_shim}' browser_wasi_shim
  chmod -R +w .
  substituteAllInPlace index.html
  cd ..
  if ! [ -e favicon.ico ] && [ -e static/icon.svg ]; then
      tmpPng="$(mktemp --suffix=.png)"
      rsvg-convert static/icon.svg \
        --width 64 \
        --output "$tmpPng"
      convert "$tmpPng" -define icon:auto-resize=64,48,32,16 favicon.ico
      rm "$tmpPng"
  fi
  if ! [ -e apple-touch-icon.png ] && [ -e static/icon.svg ]; then
      rsvg-convert static/icon.svg \
        --width 180 \
        --output apple-touch-icon.png
  fi
  for f in static/*.html; do
    mv $f .
  done
''
