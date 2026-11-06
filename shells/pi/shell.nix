# Flake-free shell with a current pi, independent of your channel.
#
#   nix-shell ~/base-nix/shells/pi/shell.nix --run "pi --version"
#   nix-shell ~/base-nix/shells/pi/shell.nix          # interactive: run `pi`
#
# The nixpkgs rev below is pinned (immutable tarball URL), so this always gives
# pi 1.5.0 even if <nixpkgs> (your channel) is old. No hash is given on purpose:
# fetchTarball is impure here, which is fine for nix-shell, and the URL already
# pins the exact content.
#
# To move it forward: replace the rev with a newer commit from
#   https://github.com/NixOS/nixpkgs/commits/nixos-unstable
{ nixpkgs ? builtins.fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/40b88f09a5afd6ed3356df4ba4977c789036a69e.tar.gz" }:

let
  pkgs = import nixpkgs { };
in
pkgs.mkShell {
  packages = [ pkgs.pi-coding-agent ];
}
