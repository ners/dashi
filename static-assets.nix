{ inputs
, lib
, runCommand
, fetchFromGitHub
, buildNpmPackage
, imagemagick
, librsvg
, dashi
, clean-css-cli
, gzip
}:

let
  browser_wasi_shim = buildNpmPackage {
    pname = "browser_wasi_shim";
    version = "0.4.2";
    src = fetchFromGitHub {
      owner = "haskell-wasm";
      repo = "browser_wasi_shim";
      rev = "0e10ea9465a098d1ee2cf3e09ed050102f0ead1a";
      hash = "sha256-j/UhO3RvTF0NFE8gfbKopjBDdBPn1UdS01PQJixJMZc=";
    };
    npmDepsHash = "sha256-eehX/bQoMo0rfCq6GF4ood0+xbRagMK4gWGXlZtpfJ4=";
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
      rsvg-convert "${./static/icon.svg}" \
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
      rsvg-convert "${./static/icon.svg}" \
        --background-color '#3457D5' \
        --width 180 \
        --output "$out"
    '';
  dashi-css = runCommand "dashi.css"
    {
      nativeBuildInputs = [
        # TODO: switch to csso-cli when merged
        # https://github.com/NixOS/nixpkgs/pull/480441
        clean-css-cli
        dashi
        gzip
      ];
    }
    ''
      function compare() {
        echo "$1: $(numfmt --to=si --suffix=B $2) -> $(numfmt --to=si --suffix=B $3) ($(( $3 * 100 / $2 - 100 ))%)"
      }
      dashi-style > "$out"
      size1="$(cat "$out" | wc -l)"
      gzip1="$(gzip -c "$out" | wc -c)"
      cleancss --output "$out"{,}
      size2="$(cat "$out" | wc -c)"
      gzip2="$(gzip -c "$out" | wc -c)"
      compare "$name" $size1 $size2
      compare "$name.gz" $gzip1 $gzip2
    '';
in
runCommand "dashi-static-assets" { } ''
  mkdir -p "$out"
  cd "$out"
  cp -r "${./static}" ./static
  cd static
  chmod -R +w .
  cp "${inputs.mdi-webfont}"/*.woff2 .
  cp -r "${browser_wasi_shim}" browser_wasi_shim
  cp "${dashi-css}" dashi.css
  cd ..
  cp "${favicon}" favicon.ico
  cp "${apple-touch-icon}" apple-touch-icon.png
  mv static/*.html .
''
