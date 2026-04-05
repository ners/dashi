{ inputs
, lib
, runCommand
, fetchFromGitHub
, buildNpmPackage
, imagemagick
, librsvg
, dashi
, csso-cli
, brotli
, gzip
, withCss ? true
}:

let
  browser_wasi_shim = buildNpmPackage {
    pname = "browser_wasi_shim";
    version = "0.4.2";
    src = fetchFromGitHub {
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
  favicon = runCommand "favicon.ico"
    {
      nativeBuildInputs = [
        imagemagick
        librsvg
      ];
    }
    ''
      tmpPng="$(mktemp --suffix=.png)"
      rsvg-convert "${./dashi/static/icon.svg}" \
        --width 64 \
        --output "$tmpPng"
      convert "$tmpPng" -define icon:auto-resize=64,48,32,16 "$out"
      rm "$tmpPng"
    '';
  apple-touch-icon = runCommand "apple-touch-icon.png"
    {
      nativeBuildInputs = [
        librsvg
      ];
    }
    ''
      rsvg-convert "${./dashi/static/icon.svg}" \
        --background-color '#3457D5' \
        --width 180 \
        --output "$out"
    '';
  dashi-css = runCommand "dashi.css"
    {
      nativeBuildInputs = [
        brotli
        csso-cli
        dashi
        gzip
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
      mkdir "$out"
      cd "$out"
      dashi-style > dashi.css
      compress dashi{,.min}.css "csso --input dashi.css --output dashi.min.css"
    '';
in
runCommand "dashi-static-assets" { } ''
  mkdir -p "$out"
  cd "$out"
  cp -r "${./dashi/static}" ./static
  cd static
  chmod -R +w .
  cp "${inputs.mdi-webfont}"/*.woff2 .
  cp -r "${browser_wasi_shim}" browser_wasi_shim
  ${lib.optionalString withCss ''
    cp "${dashi-css}"/* .
  ''}
  cd ..
  cp "${favicon}" favicon.ico
  cp "${apple-touch-icon}" apple-touch-icon.png
  mv static/*.html .
''
