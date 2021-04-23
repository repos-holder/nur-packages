{ stdenv, fetchFromGitHub, meson, pkgconfig, libX11, libXdamage
, libXcomposite, libXrender, libXext, libXxf86vm, libXtst, libdrm
, vulkan-loader, wayland, wayland-protocols, libxkbcommon, libcap
, SDL2, mesa, libinput, pixman, xcbutilerrors, xcbutilwm, glslang
, ninja, libXi, makeWrapper, xwayland, libXres, libuuid, xcbutilrenderutil }:

stdenv.mkDerivation rec {
  pname = "gamescope";
  version = "3.7.1";

  src = fetchFromGitHub {
    owner = "Plagman";
    repo = "gamescope";
    #rev = version;
    rev = "a85c8d761c48789b1cc2055afa1d62cba382ccda";
    #sha256 = "0l3rrjq743zm5bi8b942rr41gccg8nvc7m47xj3db7slsj2zp99n";
    sha256 = "1gjlvi9ihan156a2adnw59h7ad1913iiw6za9by0b96x2m6s486b";
    fetchSubmodules = true;
  };

  preConfigure = ''
    substituteInPlace meson.build \
      --replace "'examples=false'" "'examples=false', 'logind-provider=systemd', 'libseat=disabled'"
  '';

  postInstall = ''
    wrapProgram $out/bin/gamescope \
      --prefix PATH : "${stdenv.lib.makeBinPath [ xwayland ]}"
  '';

  buildInputs = [
    libX11 libXdamage libXcomposite libXrender libXext libXxf86vm
    libXtst libdrm vulkan-loader wayland wayland-protocols
    libxkbcommon libcap SDL2 mesa libinput pixman xcbutilerrors
    xcbutilwm libXi libXres libuuid xcbutilrenderutil xwayland
  ];
  nativeBuildInputs = [ meson pkgconfig glslang ninja makeWrapper ];
}
