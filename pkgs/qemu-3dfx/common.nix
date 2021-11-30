{ lib, stdenv, fetchFromGitHub, writeScriptBin }:

rec {
  src = fetchFromGitHub {
    owner = "kjliew";
    repo = "qemu-3dfx";
    rev = "41a3453a1da781a23d32abb09bf88c3e471515dc";
    sha256 = "072n44q21lwhym432k7raccmi3045rq91k0011km6xry7dmbl1gy";
  };

  fakegit = writeScriptBin "git" ''
    #! ${stdenv.shell}
    if [ "$*" = "rev-parse HEAD" ]; then
      echo "${src.rev}"
    else
      exit 1
    fi
  '';

  meta = with lib; {
    homepage = src.meta.homepage;
    description = "MESA GL/3Dfx Glide pass-through for QEMU";
    license = licenses.gpl2Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
