{ lib, buildEnv, callPackage, makeWrapper }:

let
  dfx = callPackage ./3dfx.nix {};
  mesa = dfx.overrideAttrs (oldAttrs: rec {
    sourceRoot = "source/wrappers/mesa";

    installPhase = ''
      install -Dm644 opengl32.dll $out/opengl32.dll
    '';      
  });
in buildEnv {
  name = "qemu-3dfx-wrappers";

  paths = [ 3dfx mesa ];

  inherit (dfx) meta;
}
