# Fallback bootloader for Raspberry Pi 5 boots *without* EFI firmware
# (e.g. U-Boot / standard NixOS ARM64 SD image).
#
# default.nix imports this module only when /sys/firmware/efi is missing, so:
#   * Pi 5 with rpi5-uefi (EDK2) -> systemd-boot, as configuration.nix says
#   * Pi 5 with U-Boot / extlinux -> generic-extlinux-compatible
{ lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;

  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;
}
