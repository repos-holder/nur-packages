{ stdenv, fetchFromGitHub, kernel ? null, lib, bc }:

with lib;

let
  modDestDir = "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/ath/ath10k";
  subfolder = "ath10k-${lib.versions.majorMinor kernel.version}";
in stdenv.mkDerivation {
  pname = "ath10k-ct";
  version = "2022-05-14";

  src = fetchFromGitHub {
    owner = "greearb";
    repo = "ath10k-ct";
    rev = "f808496fcc6b1f68942914117aebf8b3f8d52bb3";
    sha256 = "sha256-T/0sOO5vJpWv5+O0UP0N8V1fM6dLf11EmhBCzXTUesM=";
  };

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ bc ];

  preConfigure = ''
    makeFlags="$makeFlags M=$(pwd)/${subfolder}"
    xz -d < ${kernel.src} | tar xf -
    cp linux-${kernel.version}/drivers/net/wireless/ath/*.h .
  '';

  makeFlags = kernel.makeFlags ++ [
    "-C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "modules"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    cd ${subfolder}
    mkdir -p ${modDestDir}
    find . -name '*.ko' -exec cp --parents {} ${modDestDir} \;
    find ${modDestDir} -name '*.ko' -exec xz -f {} \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "Stand-alone ath10k driver based on Candela Technologies Linux kernel";
    homepage = src.meta.homepage;
    license = kernel.meta.license;
    platforms = platforms.linux;
    broken = (kernel == null);
    maintainers = with maintainers; [ ];
  };
}
