#!/usr/bin/env bash
# Compact build diagnosis for the no-copy-paste VM workflow (GNOME Boxes).
#
#   ./hosts/framework/diagnose.sh            # build + print only the failures
#   ./hosts/framework/diagnose.sh /tmp/b.log # reuse/keep the full log
#
# Prints at most a screenful: distinct error lines, the first real cause,
# suspicious keywords, and disk usage.
set -uo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${1:-/tmp/nixos-build.log}"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> $HOST_DIR/rebuild.sh build (fresh unstable; no activation)"
  echo "==> full log: $LOG"
  "$HOST_DIR/rebuild.sh" build >"$LOG" 2>&1
  echo "==> exit status: $?"
fi

echo
echo "=== distinct error lines:"
grep -hE "^error:" "$LOG" | sed 's/^error: //' | sort -u | head -20

echo
echo "=== first non-cascade error:"
awk '
  /^error:/ && $0 !~ /Cannot build/ && !done { print; c = 25; done = 1; next }
  c > 0 { print; c-- }
' "$LOG" | head -30

echo
echo "=== keywords:"
grep -inE "hash mismatch|no space left|unfree|not allowed|cannot download|killed|timed out|Operation not permitted" "$LOG" | head -10

echo
echo "=== disk:"
df -h / /nix 2>/dev/null
