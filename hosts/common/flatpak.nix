# Shared Flatpak setup for all desktop hosts.
{ pkgs, ... }:

{
  services.flatpak.enable = true;

  # Configure Flathub system-wide so Flatpak apps are available to all users.
  systemd.services.flatpak-flathub-remote = {
    description = "Ensure the Flathub Flatpak remote is configured";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "dbus.service" "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists \
        flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };
}
