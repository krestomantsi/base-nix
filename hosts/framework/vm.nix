# Guest integration for GNOME Boxes / QEMU: clipboard, shared folders, USB.
# Imported by configuration.nix. Harmless on bare metal — drop the import once
# the Framework is installed if you prefer a clean config.
{ pkgs, ... }:

{
  # Root daemon: the virtio-serial channel SPICE clipboard/shared-folders use.
  services.spice-vdagentd.enable = true;

  # The user-side agent. GNOME does not autostart it, and without it Boxes'
  # copy/paste and drag-and-drop stay dead.
  systemd.user.services.spice-vdagent = {
    description = "SPICE guest agent (clipboard)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      Restart = "always";
      RestartSec = 1;
    };
  };

  # Boxes shared folders (SPICE WebDAV) + qemu guest agent (hostname, shutdown).
  services.spice-webdavd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
