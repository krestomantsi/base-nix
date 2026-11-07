# Entry point for the laptop (`nixos-rebuild -f`).
#
# `nixos-rebuild -f` evaluates this file and then takes
# `config.system.build.<...>` from it, so this file must be a *system*
# expression (not a module):
#
#   sudo nixos-rebuild switch -f ~/base-nix/hosts/laptop/default.nix
#   ~/base-nix/hosts/laptop/rebuild.sh
#
# nixos-install is different: it wants a *module* via NIXOS_CONFIG:
#
#   sudo NIXOS_CONFIG=~/base-nix/hosts/laptop/configuration.nix \
#     nixos-install --root /mnt
#
# nixpkgs comes from <nixpkgs>. Use rebuild.sh to refresh root's channel to
# nixos-unstable and pass its resolved store path explicitly; a manual rebuild
# does not update the channel. Laptop rebuilds deliberately ignore tarball pins.
#
# The laptop is always UEFI, so unlike hosts/framework/default.nix there is no
# BIOS fallback module here.

import <nixpkgs/nixos> {
  configuration = ./configuration.nix;
}
