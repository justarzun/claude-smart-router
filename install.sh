#!/usr/bin/env bash
# smart-router installer
# Copies the /smart command and its sub-agents into your Claude Code config.
# Global (~/.claude) by default; use --project to install into ./.claude instead.
#
# It writes a receipt of exactly what it installed so uninstall.sh can remove
# ONLY these files and never touch your other agents/commands.
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
      echo "Usage: ./install.sh [--project] [--target DIR] [--force]"
      echo "  (default: install globally into ~/.claude, for all your repos)"
      echo "  --project   install into ./.claude (this repo only)"
      echo "  --target    install into a custom .claude directory"
      echo "  --force     overwrite a same-named file that differs from ours"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

RECEIPT="$TARGET/.smart-router-installed"

echo "Installing smart-router → $TARGET   [$SCOPE]"
mkdir -p "$TARGET/agents" "$TARGET/commands"
: > "$RECEIPT"   # fresh receipt

install_one() {
  local rel="$1"                 # e.g. agents/debugger.md
  local src="$SRC_DIR/$rel"
  local dst="$TARGET/$rel"

  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ] && ! cmp -s "$src" "$dst"; then
    echo "  ! skip   $rel  (a different file already exists — use --force to overwrite)"
    return
  fi
  cp "$src" "$dst"
  echo "$rel" >> "$RECEIPT"       # only record what we actually wrote
  echo "  ✓ $rel"
}

for f in "$SRC_DIR"/agents/*.md;   do install_one "agents/$(basename "$f")"; done
for f in "$SRC_DIR"/commands/*.md; do install_one "commands/$(basename "$f")"; done

echo ""
echo "Done. Receipt written to: $RECEIPT"
echo "In Claude Code, run:   /smart <your request>"
echo "(If /smart isn't listed yet, run /reload-skills or start a new session.)"
