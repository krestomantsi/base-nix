# Entry point for the Raspberry Pi 5 (`nixos-rebuild -f`).
#
# `nixos-rebuild -f` evaluates this file and reads `config.system.build.*`, so
# it wraps configuration.nix in `import <nixpkgs/nixos>`:
#
#   ~/base-nix/hosts/raspberry/rebuild.sh
#   sudo nixos-rebuild switch -f ~/base-nix/hosts/raspberry/default.nix
#
# For `nixos-install`, pass configuration.nix directly via NIXOS_CONFIG (or run
# `./hosts/raspberry/rebuild.sh --install /mnt`).

import <nixpkgs/nixos> {
  # configuration.nix defaults to UEFI (systemd-boot for rpi5-uefi / EDK2).
  # When booted without EFI firmware (e.g. U-Boot / standard NixOS ARM64 SD
  # image), automatically switch to generic-extlinux-compatible instead.
  configuration = { lib, ... }: {
    imports = [ ./configuration.nix ]
      ++ lib.optional (!builtins.pathExists /sys/firmware/efi) ./bootloader-extlinux.nix;
  };
}
