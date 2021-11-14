{ stdenv, fetchFromGitHub, gnused, unixtools, perl, gnumake, which, fetchurl, writeScriptBin, pkgsCross }:

let
  qemu-3dfx = import ./common.nix { inherit fetchFromGitHub writeScriptBin stdenv; };
  pexports = stdenv.mkDerivation rec {
    pname = "pexports";
    version = "0.47";

    src = fetchurl {
      url = "mirror://sourceforge/project/mingw/MinGW/Extension/pexports/pexports-${version}/pexports-${version}-mingw32-src.tar.xz";
      sha256 = "11581a7dczrb4rk15hcx9xaqgj8kx7g4v4qwfym3awxxg4wqa4py";
    };
  };
in stdenv.mkDerivation {
  pname = "qemu-3dfx-wrappers";
  version = "1.0";

  inherit (qemu-3dfx) src;

  enableParallelBuilding = false;

  sourceRoot = "source/wrappers/3dfx";

  nativeBuildInputs = [ which gnumake gnused unixtools.xxd pexports perl pkgsCross.mingw32.buildPackages.gcc qemu-3dfx.fakegit ];

  configurePhase = ''
    mkdir build && cd build
    bash ../../../scripts/conf_wrapper
  '';

  installPhase = ''
    install -Dm644 fxmemmap.vxd $out/98/windows/system/fxmemmap.vxd
    install -Dm644 glide.dll glide2x.dll glide3x.dll $out/98/windows/system

    install -Dm644 fxptl.sys $out/xp/windows/system32/drivers/fxptl.sys
    install -Dm644 glide.dll glide2x.dll glide3x.dll $out/xp/windows/system32
    install -Dm644 instdrv.exe $out/xp
  '';
}
