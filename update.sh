#!/usr/bin/env bash
#
# seamlessvim updater: pull the config and refresh plugins + tools.
#
#   ./update.sh           # git pull, then update plugins/tools
#   ./update.sh --yes     # non-interactive
#
# Env:
#   SEAMLESSVIM_NO_PULL=1  skip git pull (update tools only)

set -euo pipefail

ASSUME_YES="${SEAMLESSVIM_ASSUME_YES:-0}"
NO_PULL="${SEAMLESSVIM_NO_PULL:-0}"
CONFIG_DIR="${SEAMLESSVIM_TARGET:-$HOME/.config/nvim}"

for arg in "$@"; do
  case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help)
      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }
run() {
  echo "+ $*"
  "$@" </dev/null
}

export PATH="$HOME/.local/bin:$PATH"

if [ "$NO_PULL" != 1 ] && [ -d "$CONFIG_DIR/.git" ]; then
  log "git pull in $CONFIG_DIR"
  run git -C "$CONFIG_DIR" pull --ff-only
fi

log "plugins (lazy.nvim)"
run nvim --headless "+Lazy! restore" "+Lazy! sync" "+qa"

log "LSP / formatters / debug adapters (mason)"
run nvim --headless "+MasonToolsUpdateSync" "+qa"

log "tree-sitter parsers"
run nvim --headless "+lua require('nvim-treesitter').install(require('config.parsers')):wait(600000)" "+qa"

if command -v cs >/dev/null 2>&1; then
  log "scala tools (coursier)"
  run cs install metals scalafmt || echo "coursier install failed (optional)"
fi

log "done"
