# TEMPLATE — this file must be regenerated on the actual Framework Desktop.
#
# On the installed system (or from the NixOS ISO with the target mounted):
#   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
# then copy that file over this one, e.g.:
#   sudo cp /etc/nixos/hardware-configuration.nix ~/base-nix/hosts/framework/
#
# The file-system UUIDs below are PLACEHOLDERS. Booting this host without
# replacing them will drop you into an emergency shell.
#
# Everything else here is what the Framework Desktop (AMD Ryzen AI Max,
# X870E-class platform, 2x NVMe) needs as a sane starting point.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0000-0000";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted
  # networking (the default) this is the recommended approach.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
