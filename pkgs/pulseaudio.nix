{ lib
, stdenv
, fetchurl
, pkg-config
  # , autoreconfHook
, libsndfile
, libtool
, makeWrapper
, perlPackages
, xorg
, libcap
, alsa-lib
, glib
, dconf
, avahi
, libjack2
, libasyncns
, lirc
, dbus
, sbc
, bluez5
, udev
, openssl
, fftwFloat
, soxr
, speexdsp
, systemd
, webrtc-audio-processing
, intltool

, meson
, ninja
, libatomic_ops
, json_c
, gettext
, valgrind
, tdb
, gtk3
, orc
, elogind

, x11Support ? false

, useSystemd ? true

, # Whether to support the JACK sound system as a backend.
  jackaudioSupport ? false

, # Whether to build the OSS wrapper ("padsp").
  ossWrapper ? true

, airtunesSupport ? false

, bluetoothSupport ? true

, remoteControlSupport ? false

, zeroconfSupport ? false

, # Whether to build only the library.
  libOnly ? false

  # , CoreServices
  # , AudioUnit
  # , Cocoa
, tcp_wrappers
, gst_all_1
, check
}:

stdenv.mkDerivation rec {
  name = "${if libOnly then "lib" else ""}pulseaudio-${version}";
  version = "15.0";

  #src = fetchTarball {
  #  url = "http://freedesktop.org/software/pulseaudio/releases/pulseaudio-${version}.tar.xz";
  #  sha256 = "0wmr4ahvzvr0603h2dfl65dra1ncdrq43ia03a1jmyzi063d4mgp";
  #};
  src = derivation rec {
    url = "http://freedesktop.org/software/pulseaudio/releases/pulseaudio-${version}.tar.xz";
    name = builtins.baseNameOf url;
    urls = [ url ];
    unpack = false;

    builder = "builtin:fetchurl";
    system = "builtin";
    outputHashMode = "flat"; outputHashAlgo = "sha256";
    preferLocalBuild = true;
    #outputHash = "0wmr4ahvzvr0603h2dfl65dra1ncdrq43ia03a1jmyzi063d4mgp";
    outputHash = "1851rg4h6sjwanvd294hn52z321rc6vbs4gbfrlw53597dx8h2x4";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = ([
    pkg-config

    perlPackages.perl
    perlPackages.XMLParser
    intltool
    meson
    ninja
    libsndfile
    libatomic_ops
    speexdsp
    libtool
    json_c
    gettext
    valgrind
    tdb
    gtk3
    orc
    elogind


    makeWrapper
    tcp_wrappers
    xorg.libXtst
    avahi
    libjack2
    lirc
    xorg.xlibsWrapper
    xorg.libXtst
    xorg.libXi
    openssl
    gst_all_1.gstreamer
    gst_all_1.gstreamermm
    check
  ]);

  propagatedBuildInputs =
    lib.optionals stdenv.isLinux [ libcap ];

  buildInputs =
    [ libtool libsndfile soxr speexdsp fftwFloat ]
    ++ lib.optionals stdenv.isLinux [ dbus ]
    # ++ lib.optionals stdenv.isDarwin [ CoreServices AudioUnit Cocoa ]
    ++ #lib.optionals (!libOnly) (
      [ libasyncns webrtc-audio-processing ]
      ++ lib.optional jackaudioSupport libjack2
      ++ lib.optionals x11Support [ xorg.xlibsWrapper xorg.libXtst xorg.libXi ]
      ++ lib.optional useSystemd systemd
      ++ lib.optionals stdenv.isLinux [ alsa-lib udev ]
      ++ lib.optional airtunesSupport openssl
      ++ lib.optionals bluetoothSupport [ bluez5 sbc ]
      # ++ lib.optional remoteControlSupport
      ++ lib.optional zeroconfSupport avahi
    #)
;
  buildPhase = ''
    cd ..
    meson setup --reconfigure --prefix=$out -Dsystemduserunitdir=$out/lib/systemd/user -Dudevrulesdir=$out/lib/udev/rules.d build
    ninja -C build 
  '';
  installPhase = ''
    ninja -C build install
  '';


  enableParallelBuilding = true;

  postInstall = lib.optionalString libOnly ''
    rm -rf $out/{bin,share,etc,lib/{pulse-*,systemd}}
    sed 's|-lltdl|-L${libtool.lib}/lib -lltdl|' -i $out/lib/pulseaudio/libpulsecore-${version}.la
  ''
  + ''
    moveToOutput lib/cmake "$dev"
    rm -f $out/bin/qpaeq # this is packaged by the "qpaeq" package now, because of missing deps
  '';

  preFixup = lib.optionalString (stdenv.isLinux && (stdenv.hostPlatform == stdenv.buildPlatform)) ''
    wrapProgram $out/libexec/pulse/gsettings-helper \
     --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/${name}" \
     --prefix GIO_EXTRA_MODULES : "${lib.getLib dconf}/lib/gio/modules"
  '';

  passthru = {
    pulseDir = "lib/pulse-" + lib.versions.majorMinor version;
  };

  meta = {
    description = "Sound server for POSIX and Win32 systems";
    homepage = "http://www.pulseaudio.org/";
    license = lib.licenses.lgpl2Plus;
    maintainers = with lib.maintainers; [ lovek323 ];
    platforms = lib.platforms.unix;

    longDescription = ''
      PulseAudio is a sound server for POSIX and Win32 systems.  A
      sound server is basically a proxy for your sound applications.
      It allows you to do advanced operations on your sound data as it
      passes between your application and your hardware.  Things like
      transferring the audio to a different machine, changing the
      sample format or channel count and mixing several sounds into
      one are easily achieved using a sound server.
    '';
  };
}
