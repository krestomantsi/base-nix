# Entry point for the Framework Desktop (`nixos-rebuild -f`).
#
# `nixos-rebuild -f` evaluates this file and then takes
# `config.system.build.<...>` from it, so this file must be a *system*
# expression (not a module). That is why it wraps configuration.nix in
# `import <nixpkgs/nixos>`, and why nixos-rebuild alone accepts it:
#
#   sudo nixos-rebuild switch -f ~/base-nix/hosts/framework/default.nix
#   ~/base-nix/hosts/framework/rebuild.sh
#
# nixos-install is different: it wants a *module* and passes it as
# `-I nixos-config=`, so for the installer use configuration.nix directly:
#
#   sudo NIXOS_CONFIG=~/base-nix/hosts/framework/configuration.nix \
#     nixos-install --root /mnt
#
# nixpkgs comes from <nixpkgs>. Use rebuild.sh to refresh root's channel to
# nixos-unstable and pass its resolved store path explicitly; a manual rebuild
# does not update the channel. Normal rebuilds deliberately ignore tarball pins.

import <nixpkgs/nixos> {
  # configuration.nix stays untouched; the BIOS fallback is only pulled in on
  # machines that booted without EFI firmware (e.g. the QEMU/Boxes test VM,
  # which has GRUB on /dev/vda instead of an ESP).
  configuration = { lib, ... }: {
    imports = [ ./configuration.nix ]
      ++ lib.optional (!builtins.pathExists /sys/firmware/efi) ./bootloader-bios.nix;
  };
}
