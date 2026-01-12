{ inputs
, lib
, runCommand
, fetchFromGitHub
, buildNpmPackage
, imagemagick
, librsvg
}:

let
  browser_wasi_shim = buildNpmPackage {
    pname = "browser_wasi_shim";
    version = "0.4.2";
    src = fetchFromGitHub {
      owner = "haskell-wasm";
      repo = "browser_wasi_shim";
      rev = "fce68df4ad2bc9cfe6581a234587a76981882186";
      hash = "sha256-FFBG5VPFvONBz+eUD/YUR3SSy8gfAsuWB9Avi8S9yqQ=";
    };
    npmDepsHash = "sha256-ErxU2EA+Enh5Bpbk3rsTrgeQnMktLjv9eNE0h5phntY=";
    #nativeBuildInputs = with pkgs; [
    #  closurecompiler
    #];
    postInstall = ''
      cp -r "$out"/lib/node_modules/*/browser_wasi_shim/dist/*.js dist
      rm -rf "$out"
      mv dist "$out"
      #cd "$out"
      #shopt -s extglob
      #closure-compiler \
      #  --js index.js \
      #  --js !(index).js \
      #  --js_output_file=index.min.js \
      #  --jscomp_off=checkVars \
      #  --compilation_level ADVANCED_OPTIMIZATIONS \
      #  --isolation_mode=IIFE \
      #  --assume_function_wrapper \
      #  --language_in UNSTABLE
      #shopt -u extglob
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
    } ''
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
    } ''
    rsvg-convert "${./static/icon.svg}" \
      --background-color '#3457D5' \
      --width 180 \
      --output "$out"
  '';
in
runCommand "static" { } ''
  cp -r "${./static}" "$out"
  cd "$out"
  chmod -R +w .

  cp "${inputs.mdi-webfont}"/*.woff2 .
  cp "${favicon}" favicon.ico
  cp "${apple-touch-icon}" apple-touch-icon.png
  cp -r "${browser_wasi_shim}" browser_wasi_shim
''
