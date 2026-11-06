#!/usr/bin/env bash
# Compact build diagnosis for the no-copy-paste VM workflow (GNOME Boxes).
#
#   ./hosts/framework/diagnose.sh            # build + print only the failures
#   ./hosts/framework/diagnose.sh /tmp/b.log # reuse/keep the full log
#
# Prints at most a screenful: the failing derivation(s), the first failure
# block, and the /nix disk usage.
set -uo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${1:-/tmp/nixos-build.log}"

echo "==> nixos-rebuild boot -f $HOST_DIR/default.nix"
echo "==> full log: $LOG"
sudo nixos-rebuild boot -f "$HOST_DIR/default.nix" >"$LOG" 2>&1
rc=$?

echo
echo "==> exit status: $rc"

echo
echo "=== failing derivations:"
grep -E "^error: builder for '" "$LOG" | sed "s/ failed.*//" | sort -u | tail -5

echo
echo "=== first failure:"
grep -m1 -A 30 "^error: builder for '" "$LOG"

if ! grep -q "^error: builder for '" "$LOG"; then
  echo
  echo "=== no builder failure found, last 25 lines of the log:"
  tail -25 "$LOG"
fi

echo
echo "=== disk:"
df -h /nix 2>/dev/null | tail -1
exit "$rc"
