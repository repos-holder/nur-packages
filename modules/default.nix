rec {
  # Add your NixOS modules here
  #
  # my-module = ./my-module;
  logitech-k380 = ./logitech-k380.nix;
  qt5 = ./qt5.nix;
  gtk = ./gtk.nix;
  cursor = ./cursor.nix;
  jack = ./jack.nix;
  pulseaudio = ./pulseaudio.nix;
  pipewire = ./pipewire.nix;
  bambootracker = ./bambootracker.nix;
  nvidia = ./nvidia.nix;
  job = ./job.nix;
  monitor = ./monitor.nix;
  server = import ./server.nix [ edgevpn ];
  headless = ./headless.nix;
  sunshine = ./sunshine.nix;
  regdomain = ./wifi.nix;
  rkn = ./rkn.nix;
  edgevpn = ./edgevpn.nix;
  cjdns = ./cjdns.nix;
  prometheus-nut-exporter = ./prometheus-nut-exporter.nix;
  bitwig = ./bitwig.nix;
  hostapd = ./hostapd;
  hardware = import ./hardware.nix [ nvidia monitor ];
  tun2socks = ./tun2socks.nix;
  cockpit = ./cockpit.nix;
  nix-index = ./nix-index.nix;
  archisteamfarm = ./archisteamfarm.nix;
  adblock = ./adblock.nix;
  gamescope = ./gamescope.nix;
}
