{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.pipewire;
in {
  options.programs.pipewire = {
    enable = mkEnableOption ''
      the PipeWire sound server
    '';
  };

  config = mkIf cfg.enable {
    sound.enable = mkForce false;
    services.pipewire.enable = true;
    nixpkgs.config.pulseaudio = true;
    programs.dconf.enable = true;
    environment = {
      systemPackages = with pkgs; [ pavucontrol pulseeffects-pw pulseaudio ];
    };
    services.pipewire.pulse.enable = true;
  };
}
