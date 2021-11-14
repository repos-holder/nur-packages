{ buildEnv, callPackage, makeWrapper }:

let
  dfx = callPackage ./dfx.nix {};
  mesa = dfx.overrideAttrs (oldAttrs: rec {
    sourceRoot = "source/wrappers/mesa";

    installPhase = ''
      install -Dm644 opengl32.dll $out/opengl32.dll
    '';      
  });
in buildEnv {
  name = "qemu-3dfx-wrappers";

  paths = [ dfx mesa ];

  meta = with lib; {
    homepage = "http://www.qemu.org/";
    description = "A generic and open source machine emulator and virtualizer";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ eelco ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
