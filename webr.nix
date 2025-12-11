inputs: system:

let
  pkgs = inputs.webr.inputs.nixpkgs.legacyPackages.${system};
in
inputs.webr.packages.${pkgs.hostPlatform.system}.default.overrideAttrs (attrs: {
  nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.breakpointHook ];
  enableParallelBuilding = true;
  configurePhase =
    with builtins;
    let
      inherit (pkgs) lib;
      xz-version = "5.2.5";
      xz-tarball = "xz-${xz-version}.tar.gz";
      xz = pkgs.fetchurl {
        url = "https://tukaani.org/xz/${xz-tarball}/download";
        hash = "sha256-9vSRD9AzB4c4vYK/uk9JIZ0DsX6weU65HvuuQZ9KuhA=";
      };
      pcre2-version = "10.39";
      pcre2-tarball = "pcre2-${pcre2-version}.tar.gz";
      pcre2 = pkgs.fetchurl {
        url = "https://github.com/PhilipHazel/pcre2/releases/download/pcre2-${pcre2-version}/${pcre2-tarball}";
        hash = "sha256-B4G9JTbvUnmxlDRx/c29mWGihF4dLJrYSbm9mLoam9Q=";
      };
      r-version = "4.5.1";
      r-tarball = "R-${r-version}.tar.gz";
      r = pkgs.fetchurl {
        url = "https://cran.rstudio.com/src/base/R-4/${r-tarball}";
        hash = "sha256-tCp5IUADhmRbEBBbkcaHKHh9tcTIPJ9sMKzc5jLhu3A=";
      };
      ports = {
        bzip2 = rec {
          version = "1.0.6";
          url = "https://github.com/emscripten-ports/bzip2/archive/${version}.zip";
          dir = "bzip2-${version}";
          src = pkgs.fetchFromGitHub {
            owner = "emscripten-ports";
            repo = "bzip2";
            tag = version;
            hash = "sha256-Gnpn/6VQgWZy+o01vd2SzaoCyYOrUWkRTAATpCGjfas=";
          };
        };
        freetype = rec {
          version = "VER-2-13-3";
          url = "https://github.com/freetype/freetype/archive/${version}.zip";
          dir = "freetype-${version}";
          src = pkgs.fetchFromGitHub {
            owner = "freetype";
            repo = "freetype";
            tag = version;
            hash = "sha256-4l90lDtpgm5xlh2m7ifrqNy373DTRTULRkAzicrM93c=";
          };
        };
        zlib = rec {
          version = "1.3.1";
          url = "https://github.com/madler/zlib/archive/refs/tags/v${version}.tar.gz";
          dir = "zlib-${version}";
          src = pkgs.fetchFromGitHub {
            owner = "madler";
            repo = "zlib";
            tag = "v${version}";
            hash = "sha256-TkPLWSN5QcPlL9D0kc/yhH0/puE9bFND24aj5NVDKYs=";
          };
        };
      };
    in
    ''
      mkdir -p /build/source/{libs,R}/download
      ln -s ${pcre2} /build/source/libs/download/${pcre2-tarball}
      ln -s ${xz} /build/source/libs/download/${xz-tarball}
      ln -s ${r} /build/source/R/download/${r-tarball}

      export EM_CACHE=$(pwd)/.emscripten_cache-${pkgs.emscripten.version}
      mkdir -p $EM_CACHE/ports
      pushd $EM_CACHE/ports
      ${lib.concatStrings (attrValues (mapAttrs (name: value: ''
        mkdir ${name}
        pushd ${name}
        echo ${value.url} > .emscripten_url
        cp --no-preserve=mode,ownership -r ${value.src} ${value.dir}
        popd
      '') ports))}
      popd
      echo $EM_CACHE/ports/zlib/
      ls $EM_CACHE/ports/zlib/

      substituteInPlace src/Makefile \
        --replace-fail 'npm ci' 'npm ci && source $(stdenv)/setup && patchShebangs $@'
      ${attrs.configurePhase}
    '';
    buildPhase = null;
})
