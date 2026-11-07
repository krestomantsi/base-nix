#!/usr/bin/env bash
# Always refresh nixos-unstable before building this host (no tarball pins).
# Run from any directory, with or without sudo.
set -euo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM="$HOST_DIR/default.nix"
MODULE="$HOST_DIR/configuration.nix"
CHANNEL_URL="https://nixos.org/channels/nixos-unstable"
CHANNEL_PATH="/nix/var/nix/profiles/per-user/root/channels/nixos"
ACTION="${1:-switch}"
if (( $# > 0 )); then
  shift
fi

usage() {
  printf '%s\n' \
    "Usage: $0 [switch|boot|test|build|dry-build|dry-activate] [nixos-rebuild flags...]" \
    "       $0 --install [ROOT (default: /mnt)] [nixos-install flags...]" \
    "" \
    "Every build updates root's nixos channel to nixos-unstable first." \
    "The default action is switch. Reboot afterwards to use a new kernel." \
    "A failed update/build stops the script; it never falls back to stale nixpkgs."
}

case "$ACTION" in
  -h|--help) usage; exit 0 ;;
  switch|boot|test|build|dry-build|dry-activate|--install) ;;
  *) usage >&2; exit 2 ;;
esac

# Parse before elevating, so a relative install root keeps its original meaning.
INSTALL_ROOT="/mnt"
if [[ "$ACTION" == "--install" && $# -gt 0 && "$1" != -* ]]; then
  INSTALL_ROOT="$(realpath -m -- "$1")"
  shift
fi

# Do not allow forwarded flags to replace the freshly updated package source
# or the host entry point. --upgrade is unnecessary: we update explicitly.
for arg in "$@"; do
  case "$arg" in
    -I*|-f*|--file|--file=*|--flake|--flake=*|--upgrade|--upgrade-all|--rollback|--root|--root=*)
      echo "Error: $arg would override this script's source, action or install root." >&2
      exit 2
      ;;
  esac
done

# Builds/dry runs may evaluate a hardware template, but never deploy one.
# Check before sudo or a channel update, including for fresh installs.
case "$ACTION" in
  switch|boot|test|--install)
    HARDWARE="$HOST_DIR/hardware-configuration.nix"
    if [[ ! -f "$HARDWARE" ]]; then
      echo "Error: hardware configuration is missing: $HARDWARE" >&2
      exit 1
    fi
    if grep -Eq '00000000-0000-0000-0000-000000000000|0000-0000' "$HARDWARE"; then
      echo "Error: $HARDWARE still contains placeholder disk UUIDs." >&2
      echo "Generate the hardware config on the target machine and copy it here:" >&2
      echo "  sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix" >&2
      echo "  cp /tmp/hw.nix \"$HARDWARE\"" >&2
      exit 1
    fi
    ;;
esac

if (( EUID != 0 )); then
  if [[ "$ACTION" == "--install" ]]; then
    exec sudo -- "$HOST_DIR/rebuild.sh" "$ACTION" "$INSTALL_ROOT" "$@"
  fi
  exec sudo -- "$HOST_DIR/rebuild.sh" "$ACTION" "$@"
fi

echo "==> updating root's nixos channel to nixos-unstable"
nix-channel --add "$CHANNEL_URL" nixos
nix-channel --update nixos

# Resolve once so the whole build uses the same updated channel generation.
NIXPKGS="$(readlink -f "$CHANNEL_PATH")"
if [[ ! -f "$NIXPKGS/nixos/default.nix" ]]; then
  echo "Error: updated nixpkgs is missing at $CHANNEL_PATH" >&2
  exit 1
fi
extra=(-I "nixpkgs=$NIXPKGS")
echo "==> nixpkgs: $NIXPKGS"

if [[ "$ACTION" == "--install" ]]; then
  echo "==> nixos-install --root $INSTALL_ROOT (module: $MODULE)"
  exec env NIXOS_CONFIG="$MODULE" nixos-install --root "$INSTALL_ROOT" "${extra[@]}" "$@"
fi

echo "==> nixos-rebuild $ACTION -f $SYSTEM"
exec nixos-rebuild "$ACTION" -f "$SYSTEM" "${extra[@]}" "$@"
