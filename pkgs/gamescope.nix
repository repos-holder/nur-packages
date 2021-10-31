{ lib, stdenv, fetchFromGitHub, meson, pkgconfig, libdrm, xorg
, wayland, wayland-protocols, libxkbcommon, libcap
, SDL2, mesa, libinput, pixman, xcbutilerrors, xcbutilwm, glslang
, ninja, makeWrapper, xwayland, libuuid, xcbutilrenderutil
, pipewire, stb, writeText, wlroots
, callPackage, fetchurl }:

let
  stbpc = writeText "stbpc" ''
    prefix=${stb}
    includedir=''${prefix}/include/stb
    Cflags: -I''${includedir}
    Name: stb
    Version: ${stb.version}
    Description: stb
  '';
  stb_ = stb.overrideAttrs (oldAttrs: rec {
    installPhase = ''
      ${oldAttrs.installPhase}
      install -Dm644 ${stbpc} $out/lib/pkgconfig/stb.pc
    '';
  });
  vulkan-headers = callPackage (fetchurl {
    name = "vulkan-headers-latest.nix";
    url = "https://raw.githubusercontent.com/NixOS/nixpkgs/12cf7636fb8bc0981e0cb99dcd544d3ce180868e/pkgs/development/libraries/vulkan-headers/default.nix";
    sha256 = "0y5k0fscv02p445knxniazcx7xm4nbds0xqkbkg9s907cv69nvph";
  }) {};
  vulkan-loader = (callPackage (fetchurl {
    name = "vulkan-loader-latest.nix";
    url = "https://raw.githubusercontent.com/NixOS/nixpkgs/12cf7636fb8bc0981e0cb99dcd544d3ce180868e/pkgs/development/libraries/vulkan-loader/default.nix";
    sha256 = "132qw2mw1zmi8qzz18l05ahwljg8czldkj43ib7ihrayv82ciyww";
  }) {}).override { inherit vulkan-headers; };
in stdenv.mkDerivation rec {
  pname = "gamescope";
  version = "3.9.1";

  src = fetchFromGitHub {
    owner = "Plagman";
    repo = "gamescope";
    rev = version;
    sha256 = "05a1sj1fl9wpb9jys515m96958cxmgim8i7zc5mn44rjijkfbfcb";
    fetchSubmodules = true;
  };

  preConfigure = ''
    substituteInPlace meson.build \
      --replace "'examples=false'" "'examples=false', 'logind-provider=systemd', 'libseat=disabled'"
  '';

  postInstall = ''
    wrapProgram $out/bin/gamescope \
      --prefix PATH : "${lib.makeBinPath [ xwayland ]}"
  '';

  buildInputs = with xorg; [
    libX11 libXdamage libXcomposite libXrender libXext libXxf86vm
    libXtst libdrm vulkan-loader wayland wayland-protocols
    libxkbcommon libcap SDL2 mesa libinput pixman xcbutilerrors
    xcbutilwm libXi libXres libuuid xcbutilrenderutil xwayland
    pipewire wlroots
  ];
  nativeBuildInputs = [ meson pkgconfig glslang ninja makeWrapper stb_ ];

  meta = with lib; {
    description = "The micro-compositor formerly known as steamcompmgr";
    license = licenses.bsd2;
    homepage = src.meta.homepage;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
    broken = true;
  };
}
