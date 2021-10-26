{ lib, stdenv, fetchFromGitHub, meson, pkgconfig, libX11, libXdamage
, libXcomposite, libXrender, libXext, libXxf86vm, libXtst, libdrm
, vulkan-loader, wayland, wayland-protocols, libxkbcommon, libcap
, SDL2, mesa, libinput, pixman, xcbutilerrors, xcbutilwm, glslang
, ninja, libXi, makeWrapper, xwayland, libXres, libuuid, xcbutilrenderutil
, pipewire, stb, writeText, wlroots, vulkan-headers }:

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

  buildInputs = [
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
  };
}
