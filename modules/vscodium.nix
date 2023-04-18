{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vscodium;
in {
  options.programs.vscodium = {
    enable = mkEnableOption ''
      VSCodium program
    '';
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ vscodium ];
    };
    # VSCodium
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
