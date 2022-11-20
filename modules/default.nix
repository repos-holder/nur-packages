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
  wifi = ./wifi.nix;
  rkn = ./rkn.nix;
  rkn2 = ./rkn2.nix;
  edgevpn = ./edgevpn.nix;
  cjdns = ./cjdns.nix;
  prometheus-nut-exporter = ./prometheus-nut-exporter.nix;
  bitwig = ./bitwig.nix;
  hostapd = ./hostapd;
  hardware = import ./hardware [ nvidia monitor ];
  tun2socks = ./tun2socks.nix;
  cockpit = ./cockpit.nix;
  nix-index = ./nix-index.nix;
  archisteamfarm = ./archisteamfarm.nix;
  adblock = ./adblock.nix;
}
