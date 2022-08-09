{ lib, stdenv, fetchFromGitHub, kernel ? null }:

let
  config = kernel.configfile.structuredConfig;
in stdenv.mkDerivation rec {
  pname = "iwl20x_ax_enable";
  version = "181c0e28e853835265bdaf14ac6fbff99dc9ed00";

  src = fetchFromGitHub {
    owner = "80501";
    repo = "iwl20x_ax_enable";
    #branch = "main_wrdd";
    rev = version;
    sha256 = "sha256-d73GaN+L+WAzd2RQVCed2nYIzd9sBZ3DkGDjtbwlgrQ=";
  };

  # disable LAR
  NIX_CFLAGS_COMPILE = "-DMCC=\"ID\"";

  makeFlags = [ "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" ];

  installPhase = ''
    install -Dm444 iwl20x_ax_en.ko $out/lib/modules/${kernel.modDirVersion}/misc/iwl20x_ax_en.ko
  '';

  meta = with lib; {
    description = "A kernel livepatch to enable 5 GHz AP mode on Intel cards";
    homepage = src.meta.homepage;
    license = licenses.gpl2;
    maintainers = [ ];
    platforms = platforms.linux;
    # required to build
    broken = kernel == null || (if config ? LIVEPATCH then config.LIVEPATCH.tristate != "y" else true);
  };
}
