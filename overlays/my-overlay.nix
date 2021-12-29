{ unstable, config, wireless-regdb_ }:

self: super: with super.lib;
rec {
  dtrx = super.dtrx.override {
    unzipSupport = true;
    unrarSupport = true;
  };
  lmms = super.lmms.overrideAttrs (oldAttrs: optionalAttrs (config.jack or false) {
    cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DWANT_WEAKJACK=OFF" ];
  });
  qutebrowser = super.qutebrowser.overrideAttrs (oldAttrs: {
    postFixup = ''
      ${oldAttrs.postFixup}
      wrapProgram $out/bin/qutebrowser \
        --prefix PATH : "${super.lib.makeBinPath [ super.mpv ]}"
    '';
  });
  wireless-regdb = if (config.hardware.wifi.enable or false) then wireless-regdb_ else super.wireless-regdb;
  crda = if (config.hardware.wifi.enable or false) then (super.crda.override {
    inherit wireless-regdb;
  }).overrideAttrs (oldAttrs: rec {
    makeFlags = oldAttrs.makeFlags ++ [
      "PUBKEY_DIR=${wireless-regdb}/lib/crda/pubkeys"
    ];
  }) else super.crda;
  miniupnpd = super.miniupnpd.overrideAttrs (oldAttrs: rec {
    version = "2.1.20200510";
    src = super.fetchurl {
      url = "http://miniupnp.free.fr/files/download.php?file=miniupnpd-${version}.tar.gz";
      sha256 = "12vy2bsk52kmf6g4ms7qidd1njhz7ay1yi062n2zphcw6s7p07l2";
      name = "miniupnpd-${version}.tar.gz";
    };
    #makefile = "Makefile.linux_nft";
    dontConfigure = true;
    buildFlags = [ "miniupnpd" "SRCDIR=." ];
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ super.which ];
    buildInputs = oldAttrs.buildInputs ++ (with super; [ libmnl libnftnl ]);
  });
}
