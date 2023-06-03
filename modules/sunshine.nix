{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.sunshine;
in {
  options.programs.sunshine = {
    enable = mkEnableOption "Sunshine headless server";
    user = mkOption {
      type = types.str;
    };
    games = mkOption {
      type = types.listOf types.package;
      default = [];
    };
  };

  config = mkMerge [
   (mkIf cfg.enable {
      hardware.uinput.enable = true;
      users.extraUsers.${cfg.user} = {
        extraGroups = [ "uinput" "video" ];
        packages = cfg.games;
      };
      security.wrappers.sunshine = {
        owner = "root";
        group = "root";
        capabilities = "cap_sys_admin+p";
        source = "${pkgs.sunshine}/bin/sunshine";
      };
      systemd.user.services.sunshine = {
        path = cfg.games;
        description = "Sunshine headless server";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${config.security.wrapperDir}/sunshine";
          RestartSec = 3;
          Restart = "always";
        };
      };
   })
  ];
}
