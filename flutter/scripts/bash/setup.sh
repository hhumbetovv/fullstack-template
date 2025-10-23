#!/usr/bin/env bash
set -e
echo "⚙️  Setting up project alias..."
RC_FILES=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")
LINE='[ -f .project_aliases ] && source .project_aliases'
for RC_FILE in "${RC_FILES[@]}"; do
  if [ -f "$RC_FILE" ]; then
    if ! grep -qxF "$LINE" "$RC_FILE"; then
      echo "$LINE" >> "$RC_FILE"
    fi
  else
    echo "$LINE" > "$RC_FILE"
  fi
done
source .project_aliases