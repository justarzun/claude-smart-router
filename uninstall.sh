#!/usr/bin/env bash
# smart-router uninstaller
# Removes ONLY the files this package installed. It never deletes your other
# agents or commands, and never removes a non-empty directory.
#
# By default it removes a file only if it still matches what we shipped; a file
# you customized is KEPT (use --force to remove it anyway).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="$HOME/.claude"
SCOPE="global (~/.claude)"
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project) TARGET="$(pwd)/.claude"; SCOPE="project (./.claude)" ;;
    --target)  shift; TARGET="${1:?--target needs a directory}" ;;
    --force)   FORCE=1 ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [--project] [--target DIR] [--force]"
      echo "  --force   also remove files you customized after installing"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

RECEIPT="$TARGET/.smart-router-installed"
removed=0
kept=0

remove_one() {
  local rel="$1"
  local dst="$TARGET/$rel"
  local src="$SRC_DIR/$rel"
  [ -e "$dst" ] || return 0
  if [ "$FORCE" -ne 1 ] && [ -e "$src" ] && ! cmp -s "$src" "$dst"; then
    echo "  ! keep    $rel  (you customized it — use --force to remove)"
    kept=$((kept + 1))
    return 0
  fi
  rm -f "$dst"
  echo "  ✓ removed $rel"
  removed=$((removed + 1))
}

echo "Uninstalling smart-router ← $TARGET   [$SCOPE]"

if [ -f "$RECEIPT" ]; then
  # Receipt lists exactly the files we installed — the safest source of truth.
  while IFS= read -r rel; do
    [ -n "$rel" ] && remove_one "$rel"
  done < "$RECEIPT"
  # Drop the receipt only if nothing was deliberately kept.
  [ "$kept" -eq 0 ] && rm -f "$RECEIPT"
else
  echo "  (no receipt found — falling back to this package's file list)"
  for f in "$SRC_DIR"/agents/*.md;   do remove_one "agents/$(basename "$f")"; done
  for f in "$SRC_DIR"/commands/*.md; do remove_one "commands/$(basename "$f")"; done
fi

# Remove our dirs ONLY if they are now empty (protects your other files).
rmdir "$TARGET/agents"   2>/dev/null || true
rmdir "$TARGET/commands" 2>/dev/null || true

echo ""
echo "Done. Removed $removed file(s); kept $kept customized file(s)."
echo "Your other agents and commands were not touched."
