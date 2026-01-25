#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

if set -o | grep -Eq '^posix[[:space:]]+on$'; then
  exec bash "$0" "$@"
fi

set -e

echo "⚙️  Setting up project alias..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RC_FILES=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")

ensure_line_in_rc() {
  local line="$1"
  local file="$2"

  if [ -f "$file" ]; then
    if ! grep -qxF "$line" "$file" >/dev/null 2>&1; then
      echo "$line" >> "$file"
    fi
  else
    printf '%s\n' "$line" > "$file"
  fi
}

ALIAS_LINE="[ -f '$PROJECT_ROOT/.project_aliases' ] && source '$PROJECT_ROOT/.project_aliases'"

for RC_FILE in "${RC_FILES[@]}"; do
  ensure_line_in_rc "$ALIAS_LINE" "$RC_FILE"
done

source "$PROJECT_ROOT/.project_aliases"
