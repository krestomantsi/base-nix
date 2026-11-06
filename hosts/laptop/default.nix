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
# nixpkgs comes from <nixpkgs> (root's channel) or from ./nixpkgs.nix if you
# copy nixpkgs.nix.example there; rebuild.sh handles both.
#
# The laptop is always UEFI, so unlike hosts/framework/default.nix there is no
# BIOS fallback module here.

import <nixpkgs/nixos> {
  configuration = ./configuration.nix;
}
