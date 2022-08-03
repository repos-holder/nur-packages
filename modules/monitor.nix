{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hardware.monitor;
  position' = s: head (splitString "x" s);
  # move to hardware module
  eDP-1' = {
    setup = "00ffffffffffff004d104714000000002d190104a51d117806de50a3544c99260f5054000000010101010101010101010101010101011a3680a070381f403020350026a510000018000000100000000000000000000000000000000000100000000000000000000000000000000000fe004c513133334d314a5731350a2000cf";
    config = {
      enable = true;
      crtc = 0;
      mode = "1920x1080";
      position = "0x0";
      rate = "59.93";
    };
  };
  DP-1' = {
    setup = "00ffffffffffff0030aee66100000000331e0104b53e22783bb4a5ad4f449e250f5054a10800d100d1c0b30081c081809500a9c081004dd000a0f0703e80302035006d552100001a000000fd00283c858538010a202020202020000000fc004c454e20533238752d31300a20000000ff00564e4135433339420a2020202001f002031bf14e61605f101f05140413121103020123097f0783010000a36600a0f0701f80302035006d552100001a565e00a0a0a02950302035006d552100001ae26800a0a0402e60302036006d552100001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f";
    config = {
      enable = true;
      crtc = 1;
      mode = "3840x2160";
      position = "0x0";
      rate = "60.00";
    };
  };
in {
  options.hardware.monitor = {
    enable = mkEnableOption ''
      Adoptions for monitor
    '';
    user = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable rec {
    # move to hardware module
    programs.light.enable = true;
    users.users.${cfg.user}.extraGroups = [ "video" ];
    services.ddccontrol.enable = true;
    hardware.i2c.enable = true;
    services.autorandr = with pkgs; {
      enable = true;
      defaultTarget = "laptop";
      profiles = rec {
        laptop = {
          fingerprint.eDP-1 = eDP-1'.setup;
          config = {
            DP-1.enable = false;
            HDMI-1.enable = false;
            HDMI-2.enable = false;
            eDP-1 = eDP-1'.config;
          };
        };
        monitor = {
          fingerprint.DP-1 = DP-1'.setup;
          config = {
            eDP-1.enable = false;
            HDMI-1.enable = false;
            HDMI-2.enable = false;
            DP-1 = DP-1'.config;
          };
        };
        integer = monitor // {
          hooks.postswitch.xrandr = "${xorg.xrandr} --output DP-1 --scale 0.5x0.5 --filter nearest";
        };
        both = {
          fingerprint.eDP-1 = eDP-1'.setup;
          fingerprint.DP-1 = DP-1'.setup;
          config = {
            HDMI-1.enable = false;
            HDMI-2.enable = false;
            eDP-1 = eDP-1'.config;
            DP-1 = DP-1'.config // {
              primary = true;
              position = "${position' eDP-1'.config.mode}x0";
            };
          };
        };
      };
      hooks.postswitch = {
        xrdb = ''
          case "$AUTORANDR_CURRENT_PROFILE" in
            laptop)
              DPI=96
              ;;
            monitor|integer|both)
              DPI=144
              ;;
            *)
              echo "Unknown profle: $AUTORANDR_CURRENT_PROFILE"
              exit 1
          esac
          echo "Xft.dpi: $DPI" | ${xorg.xrdb}/bin/xrdb -merge
      '';
      } // optionalAttrs config.services.xserver.windowManager.i3.enable {
        notify-i3 = "${i3}/bin/i3-msg restart";
      };
    };
  };
}
