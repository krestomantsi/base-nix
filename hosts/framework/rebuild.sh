#!/usr/bin/env bash
# Rebuild the Framework Desktop host without flakes.
#
#   ./rebuild.sh              -> nixos-rebuild switch
#   ./rebuild.sh boot         -> nixos-rebuild boot
#   ./rebuild.sh test         -> nixos-rebuild test
#   ./rebuild.sh --install    -> nixos-install --root /mnt (run from the ISO)
#
# nixpkgs resolution order:
#   1. ./nixpkgs.nix  (copy of nixpkgs.nix.example, pinned tarball) -- if present
#   2. <nixpkgs>      (root's channel: sudo nix-channel --update)
#
# Note on the two NixOS interfaces:
#   nixos-rebuild -f <file>  expects a *system* expression  -> default.nix
#   nixos-install            expects a *module* (NIXOS_CONFIG) -> configuration.nix
set -euo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM="$HOST_DIR/default.nix"
MODULE="$HOST_DIR/configuration.nix"
PIN="$HOST_DIR/nixpkgs.nix"
ACTION="${1:-switch}"

extra=()
if [[ -f "$PIN" ]] && ! grep -q REPLACE_WITH "$PIN"; then
  echo "==> using pinned nixpkgs from $PIN"
  nixpkgs="$(nix-instantiate --eval --raw -E "import $PIN")"
  extra+=(-I "nixpkgs=$nixpkgs")
elif [[ -e /nix/var/nix/profiles/per-user/root/channels/nixos ]]; then
  # sudo drops NIX_PATH, so <nixpkgs> may not resolve for root even though the
  # channel is there. Point at the channel explicitly; `<nixpkgs/nixos>` then
  # finds the `nixos/` subdirectory of the channel.
  echo "==> using root channel /nix/var/nix/profiles/per-user/root/channels/nixos"
  extra+=(-I "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos")
else
  echo "==> using <nixpkgs> from NIX_PATH"
fi

if [[ "$ACTION" == "--install" ]]; then
  root="${2:-/mnt}"
  echo "==> nixos-install --root $root (module: $MODULE)"
  exec sudo NIXOS_CONFIG="$MODULE" nixos-install --root "$root" "${extra[@]}"
fi

echo "==> nixos-rebuild $ACTION -f $SYSTEM"

# Refuse to switch with the placeholder hardware config: that would install a
# system whose root/ESP UUIDs do not exist and leave the machine unbootable.
case "$ACTION" in
  switch|boot|test)
    if grep -q "00000000-0000-0000-0000-000000000000" "$HOST_DIR/hardware-configuration.nix"; then
      echo "error: $HOST_DIR/hardware-configuration.nix is still the TEMPLATE." >&2
      echo "       real hardware: sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix" >&2
      echo "                      sudo cp /tmp/hw.nix $HOST_DIR/hardware-configuration.nix" >&2
      echo "       QEMU/Boxes VM: cp $HOST_DIR/hardware-configuration.vm.nix $HOST_DIR/hardware-configuration.nix" >&2
      exit 1
    fi
    ;;
esac

exec sudo nixos-rebuild "$ACTION" -f "$SYSTEM" "${extra[@]}"
