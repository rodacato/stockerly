#!/bin/bash
set -e

bin/setup --skip-server
bin/setup-hooks

# Load the non-secret Kamal environment in every shell. Idempotent across rebuilds.
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q 'devcontainer/kamal-env.sh' "$rc" && continue
  {
    echo ''
    echo "export STOCKERLY_ROOT=\"$PWD\""
    echo '[ -r "$STOCKERLY_ROOT/.devcontainer/kamal-env.sh" ] && . "$STOCKERLY_ROOT/.devcontainer/kamal-env.sh"'
  } >> "$rc"
done
