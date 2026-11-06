# Non-flake entry point for the Framework Desktop.
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
# nixpkgs comes from <nixpkgs>, i.e. root's channel. Set it up once:
#
#   sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
#   sudo nix-channel --update
#
# ...or pin it with hosts/framework/nixpkgs.nix (see nixpkgs.nix.example);
# rebuild.sh passes that as -I nixpkgs=<pinned>.

import <nixpkgs/nixos> {
  configuration = ./configuration.nix;
}
