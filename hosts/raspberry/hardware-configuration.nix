# TEMPLATE — replace with `nixos-generate-config` output from the real Pi 5!
#
# rebuild.sh refuses switch/boot/test/--install while the placeholder UUIDs
# below are present, while still allowing `build` / `dry-build` evaluation.
#
# On the Raspberry Pi 5:
#   sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix
#   cp /tmp/hw.nix ~/base-nix/hosts/raspberry/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "uas"
    "sd_mod"
    "pcie_brcmstb"
    "reset-raspberrypi"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0000-0000";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
