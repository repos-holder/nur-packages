{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hardware.wifi;
  config' = kernel.configfile.structuredConfig;
in {
  options.hardware.wifi = {
    enable = mkEnableOption ''
      Wi-Fi hacks
    '';
    interface = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    services.hostapd.noScan = true;

    systemd.services.hostapd.preStart = ''
      set +e
      ${pkgs.wirelesstools}/bin/iwconfig ${cfg.interface} power off
      true
    '';

    boot.extraModprobeConfig = ''
      softdep iwlwifi pre: iwl20x_ax_en
    '';
    boot.extraModulePackages = with pkgs.nur.repos.dukzcry; [
      (iwl20x_ax_enable.override { inherit (config.boot.kernelPackages) kernel; })
    ];
    boot.kernelPatches = optionals (if config ? LIVEPATCH then config.LIVEPATCH.tristate != "y" else true) [
      {
        name = "livepatch";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          LIVEPATCH = yes;
        };
      }
    ];
  };
}
