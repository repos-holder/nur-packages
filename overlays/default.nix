{ pkgs, config ? null }:

self: super: with super.lib;
rec {
  dtrx = super.dtrx.override {
    unzipSupport = true;
    unrarSupport = true;
  };
  # https://github.com/curl/curl/issues/7621
  curlftpfs = super.curlftpfs.override {
    curl = super.curl.overrideAttrs (oldAttrs: rec {
      pname = "curl";
      version = "7.77.0";
      src = super.fetchurl {
        urls = [
          "https://curl.haxx.se/download/${pname}-${version}.tar.bz2"
          "https://github.com/curl/curl/releases/download/${super.lib.replaceStrings ["."] ["_"] pname}-${version}/${pname}-${version}.tar.bz2"
        ];
        sha256 = "1spqbn2wyfh2dfsz2p60ap4194vnvf7rqfy4ky2r69dqij32h33c";
      };
      patches = [];
      doCheck = false;
    });
  };
  lmms = super.lmms.overrideAttrs (oldAttrs: optionalAttrs (config.services.jack.enable or false) {
    cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DWANT_WEAKJACK=OFF" ];
  });
  qutebrowser = super.qutebrowser.overrideAttrs (oldAttrs: {
    postFixup = ''
      ${oldAttrs.postFixup}
      wrapProgram $out/bin/qutebrowser \
        --prefix PATH : "${super.lib.makeBinPath [ super.mpv ]}"
    '';
  });
  # https://github.com/jellyfin/jellyfin/issues/7642
  jellyfin-ffmpeg = super.jellyfin-ffmpeg.override (optionalAttrs (config.services.jellyfin.enable or false) {
    ffmpeg-full = super.ffmpeg-full.override {
      libva = let
        mesa = super.mesa.overrideAttrs (oldAttrs: rec {
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ super.gnused ];
          postPatch = ''
            ${oldAttrs.postPatch}
            MESA_VA_PIC="./src/gallium/frontends/va/picture.c"
            MESA_VA_CONF="./src/gallium/frontends/va/config.c"
            sed -i 's|handleVAEncPackedHeaderParameterBufferType(context, buf);||g' ${MESA_VA_PIC}
            sed -i 's|handleVAEncPackedHeaderDataBufferType(context, buf);||g' ${MESA_VA_PIC}
            sed -i 's|if (u_reduce_video_profile(ProfileToPipe(profile)) == PIPE_VIDEO_FORMAT_HEVC)|if (0)|g' ${MESA_VA_CONF}
            # force reporting all packed headers are supported
            sed -i 's|value = VA_ENC_PACKED_HEADER_NONE;|value = 0x0000001f;|g' ${MESA_VA_CONF}
            sed -i 's|if (attrib_list\[i\].type == VAConfigAttribEncPackedHeaders)|if (0)|g' ${MESA_VA_CONF}
            exit 1
          '';
        });
      in super.libva.overrideAttrs (oldAttrs: rec {
        mesonFlags = [ "-Ddriverdir=${mesa.drivers}/lib/dri" ];
      });
    };
  });
  evolution = super.symlinkJoin {
    name = "evolution-without-background-processes";
    paths = with super; [
      (writeShellScriptBin "evolution" ''
        ${super.evolution}/bin/evolution "$@"
        ${super.evolution}/bin/evolution --force-shutdown
      '')
      super.evolution
    ];
  };
  ddccontrol = super.ddccontrol.overrideAttrs (oldAttrs: {
    prePatch = ''
      ${oldAttrs.prePatch}
      substituteInPlace src/gddccontrol/notebook.c \
        --replace "if (mon->fallback)" "if (0)"
    '';
  });
  autorandr = super.autorandr.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [ ./autorandr.patch ];
  });
  # https://github.com/Mange/rtl8192eu-linux-driver/issues/275
  linuxPackages = super.linuxPackages.extend (lpself: lpsuper: {
    rtl8192eu = super.linuxPackages.rtl8192eu.overrideAttrs (oldAttrs: rec {
      version = "issue-275";
      src = super.fetchFromGitHub {
        owner = "Mange";
        repo = "rtl8192eu-linux-driver";
        rev = "41fddb43b3a351fce500cdc867807bfa2d3151c3";
        sha256 = "sha256-4UW1wLLRRe2IXhqpmTLIZZOLtXb3Bpj6qMwYKT6EjZM=";
      };
    });
    rtw8852be = pkgs.nur.repos.dukzcry.rtw8852be.override { kernel = super.linuxPackages.kernel; };
  });
  linuxPackages_latest = super.linuxPackages_latest.extend (lpself: lpsuper: {
    rtw8852be = pkgs.nur.repos.dukzcry.rtw8852be.override { kernel = super.linuxPackages_latest.kernel; };
  });
} // optionalAttrs (config.hardware.wifi.enable or false) {
  inherit (pkgs.nur.repos.dukzcry) wireless-regdb;
  crda = super.crda.overrideAttrs (oldAttrs: rec {
    makeFlags = oldAttrs.makeFlags ++ [
      "PUBKEY_DIR=${pkgs.nur.repos.dukzcry.wireless-regdb}/lib/crda/pubkeys"
    ];
  });
}
