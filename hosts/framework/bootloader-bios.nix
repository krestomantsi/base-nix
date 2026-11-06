# Fallback bootloader for machines *without* EFI firmware.
#
# The framework host is written for the real hardware, where systemd-boot on an
# ESP is the right choice. The QEMU/Boxes test VM was installed by the NixOS
# installer in legacy BIOS mode (GRUB on /dev/vda, no ESP), so systemd-boot
# cannot be installed there and a switch would leave the machine unbootable.
#
# default.nix imports this module only when /sys/firmware/efi is missing, so:
#   * real Framework (UEFI)  -> systemd-boot, exactly as configuration.nix says
#   * BIOS VM                -> GRUB on /dev/vda, same bootloader it was
#                               installed with
{ lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  boot.loader.grub.enable = lib.mkForce true;
  boot.loader.grub.device = lib.mkForce "/dev/vda";
  boot.loader.grub.useOSProber = lib.mkForce true;
}
