{ lib, stdenv, fetchurl, fetchpatch, python3, zlib, pkg-config, glib
, perl, pixman, vde2, alsaLib, texinfo, flex
, bison, lzo, snappy, libaio, gnutls, nettle, curl, ninja, meson
, makeWrapper, autoPatchelfHook
, attr, libcap, libcap_ng
, numaSupport ? stdenv.isLinux && !stdenv.isAarch32, numactl
, seccompSupport ? stdenv.isLinux, libseccomp
, alsaSupport ? lib.hasSuffix "linux" stdenv.hostPlatform.system && !nixosTestRunner
, pulseSupport ? !stdenv.isDarwin && !nixosTestRunner, libpulseaudio
, sdlSupport ? !stdenv.isDarwin && !nixosTestRunner, SDL2, SDL2_image
, gtkSupport ? !stdenv.isDarwin && !xenSupport && !nixosTestRunner, gtk3, gettext, vte, wrapGAppsHook
, vncSupport ? !nixosTestRunner, libjpeg, libpng
, smartcardSupport ? !nixosTestRunner, libcacard
, spiceSupport ? !stdenv.isDarwin && !nixosTestRunner, spice, spice-protocol
, ncursesSupport ? !nixosTestRunner, ncurses
, usbredirSupport ? spiceSupport, usbredir
, xenSupport ? false, xen
, cephSupport ? false, ceph
, openGLSupport ? sdlSupport, mesa, epoxy, libdrm
, virglSupport ? openGLSupport, virglrenderer
, libiscsiSupport ? true, libiscsi
, smbdSupport ? false, samba
, tpmSupport ? true
, hostCpuOnly ? false
, hostCpuTargets ? (if hostCpuOnly
                    then (lib.optional stdenv.isx86_64 "i386-softmmu"
                          ++ ["${stdenv.hostPlatform.qemuArch}-softmmu"])
                    else null)
, nixosTestRunner ? false
, fetchFromGitHub, gnused, findutils, gnugrep, writeScriptBin
}:

with lib;
let
  audio = optionalString alsaSupport "alsa,"
    + optionalString pulseSupport "pa,"
    + optionalString sdlSupport "sdl,";

  qemu-3dfx = import ./common.nix { inherit fetchFromGitHub writeScriptBin stdenv; };
in stdenv.mkDerivation rec {
  version = "5.2.0";
  pname = "qemu-3dfx"
    + lib.optionalString xenSupport "-xen"
    + lib.optionalString hostCpuOnly "-host-cpu-only"
    + lib.optionalString nixosTestRunner "-for-vm-tests";

  src = fetchurl {
    url= "https://download.qemu.org/qemu-${version}.tar.xz";
    sha256 = "1g0pvx4qbirpcn9mni704y03n3lvkmw2c0rbcwvydyr8ns4xh66b";
  };

  nativeBuildInputs = [ python3 python3.pkgs.sphinx pkg-config flex bison meson ninja autoPatchelfHook
    qemu-3dfx.fakegit gnused findutils gnugrep ]
    ++ optionals gtkSupport [ wrapGAppsHook ];
  buildInputs =
    [ zlib glib perl pixman
      vde2 texinfo makeWrapper lzo snappy
      gnutls nettle curl
    ]
    ++ optionals ncursesSupport [ ncurses ]
    ++ optionals seccompSupport [ libseccomp ]
    ++ optionals numaSupport [ numactl ]
    ++ optionals pulseSupport [ libpulseaudio ]
    ++ optionals sdlSupport [ SDL2 SDL2_image ]
    ++ optionals gtkSupport [ gtk3 gettext vte ]
    ++ optionals vncSupport [ libjpeg libpng ]
    ++ optionals smartcardSupport [ libcacard ]
    ++ optionals spiceSupport [ spice-protocol spice ]
    ++ optionals usbredirSupport [ usbredir ]
    ++ optionals stdenv.isLinux [ alsaLib libaio libcap_ng libcap attr ]
    ++ optionals xenSupport [ xen ]
    ++ optionals cephSupport [ ceph ]
    ++ optionals openGLSupport [ mesa epoxy libdrm ]
    ++ optionals virglSupport [ virglrenderer ]
    ++ optionals libiscsiSupport [ libiscsi ]
    ++ optionals smbdSupport [ samba ];

  enableParallelBuilding = true;
  dontUseMesonConfigure = true; # meson's configurePhase isn't compatible with qemu build

  outputs = [ "out" "ga" ];

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/9e403b19a1444b373874b6e9efdd728613c6badc/pkgs/applications/virtualization/qemu/fix-qemu-ga.patch";
      sha256 = "0qb32xlji4igbn0s1ykvyg4wf8zm773mpdlmq9nycgzg4yxmzbyn";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/9e403b19a1444b373874b6e9efdd728613c6badc/pkgs/applications/virtualization/qemu/9p-ignore-noatime.patch";
      sha256 = "1jyw95i5a83ad6s4lsz70jsjvh3avnhqwax17am933l8gjpml9bj";
    })
    "${qemu-3dfx.src}/00-qemu520-mesa-glide.patch"
  ] ++ optional nixosTestRunner ./force-uid0-on-9p.patch
    ++ optionals stdenv.hostPlatform.isMusl [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/alpinelinux/aports/2bb133986e8fa90e2e76d53369f03861a87a74ef/main/qemu/xattr_size_max.patch";
      sha256 = "1xfdjs1jlvs99hpf670yianb8c3qz2ars8syzyz8f2c2cp5y4bxb";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/alpinelinux/aports/2bb133986e8fa90e2e76d53369f03861a87a74ef/main/qemu/musl-F_SHLCK-and-F_EXLCK.patch";
      sha256 = "1gm67v41gw6apzgz7jr3zv9z80wvkv0jaxd2w4d16hmipa8bhs0k";
    })
    ./sigrtminmax.patch
    (fetchpatch {
      url = "https://raw.githubusercontent.com/alpinelinux/aports/2bb133986e8fa90e2e76d53369f03861a87a74ef/main/qemu/fix-sigevent-and-sigval_t.patch";
      sha256 = "0wk0rrcqywhrw9hygy6ap0lfg314m9z1wr2hn8338r5gfcw75mav";
    })
  ];

  hardeningDisable = [ "stackprotector" ];

  preConfigure = ''
    unset CPP # intereferes with dependency calculation
    # this script isn't marked as executable b/c it's indirectly used by meson. Needed to patch its shebang
    chmod +x ./scripts/shaderinclude.pl
    patchShebangs .

    cp -r --no-preserve=mode,ownership ${qemu-3dfx.src}/qemu-0/hw/3dfx ./hw/
    cp -r --no-preserve=mode,ownership ${qemu-3dfx.src}/qemu-1/hw/mesa ./hw/
    bash ${qemu-3dfx.src}/scripts/sign_commit
  '' + optionalString stdenv.hostPlatform.isMusl ''
    NIX_CFLAGS_COMPILE+=" -D_LINUX_SYSINFO_H"
  '';

  configureFlags =
    [ "--audio-drv-list=${audio}"
      "--enable-docs"
      "--enable-tools"
      "--enable-guest-agent"
      "--disable-user"
    ]
    # disable sysctl check on darwin.
    ++ optional stdenv.isDarwin "--cpu=x86_64"
    ++ optional numaSupport "--enable-numa"
    ++ optional seccompSupport "--enable-seccomp"
    ++ optional smartcardSupport "--enable-smartcard"
    ++ optional spiceSupport "--enable-spice"
    ++ optional usbredirSupport "--enable-usb-redir"
    ++ optional (hostCpuTargets != null) "--target-list=${lib.concatStringsSep "," hostCpuTargets}"
    ++ optional stdenv.isDarwin "--enable-cocoa"
    ++ optional stdenv.isDarwin "--enable-hvf"
    ++ optional stdenv.isLinux "--enable-linux-aio"
    ++ optional gtkSupport "--enable-gtk"
    ++ optional xenSupport "--enable-xen"
    ++ optional cephSupport "--enable-rbd"
    ++ optional openGLSupport "--enable-opengl"
    ++ optional virglSupport "--enable-virglrenderer"
    ++ optional tpmSupport "--enable-tpm"
    ++ optional libiscsiSupport "--enable-libiscsi"
    ++ optional smbdSupport "--smbd=${samba}/bin/smbd";

  doCheck = false; # tries to access /dev
  dontWrapGApps = true;

  postFixup = ''
    # the .desktop is both invalid and pointless
    rm $out/share/applications/qemu.desktop

    # copy qemu-ga (guest agent) to separate output
    mkdir -p $ga/bin
    cp $out/bin/qemu-ga $ga/bin/
  '' + optionalString gtkSupport ''
    # wrap GTK Binaries
    for f in $out/bin/qemu-system-*; do
      wrapGApp $f
    done
  '';
  preBuild = "cd build";

  # Add a ‘qemu-kvm’ wrapper for compatibility/convenience.
  postInstall = ''
    if [ -x $out/bin/qemu-system-${stdenv.hostPlatform.qemuArch} ]; then
      makeWrapper $out/bin/qemu-system-${stdenv.hostPlatform.qemuArch} \
                  $out/bin/qemu-kvm \
                  --add-flags "\$([ -e /dev/kvm ] && echo -enable-kvm)"
    fi
  '';

  passthru = {
    qemu-system-i386 = "bin/qemu-system-i386";
  };

  meta = with lib; {
    homepage = "http://www.qemu.org/";
    description = "A generic and open source machine emulator and virtualizer";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ eelco ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
