#!/usr/bin/env bash
#
# Runs inside the test container: install from /src, prepare fixtures, run specs.

export PATH="$HOME/.local/bin:$HOME/.local/share/coursier/bin:$PATH"
CONFIG="$HOME/.config/nvim"

section() { printf '\n====================================================================\n== %s\n====================================================================\n' "$*"; }

section "install.sh (from /src)"
if ! bash /src/install.sh --yes --no-fonts; then
  echo "FATAL: install.sh failed"
  exit 1
fi

section "prepare fixtures"
if ! bash "$CONFIG/test/fixtures/prepare.sh"; then
  echo "FATAL: fixture preparation failed"
  exit 1
fi

section "running specs"
cd "$CONFIG"
spec_rc=0
for spec in "$CONFIG"/test/spec/*_spec.lua; do
  echo
  echo "----- $(basename "$spec") -----"
  nvim --headless -u "$CONFIG/init.lua" -c "lua require('plenary.busted').run('$spec')"
  code=$?
  echo "exit code: $code"
  if [ "$code" -ne 0 ]; then spec_rc=1; fi
done

# Integration scripts are plain Lua (bash exits with their code): they exercise
# nio-based plugins (neotest) that deadlock inside busted's coroutine tests.
for it in "$CONFIG"/test/integration/*.lua; do
  [ -e "$it" ] || continue
  case "$(basename "$it")" in _*) continue ;; esac
  echo
  echo "----- $(basename "$it") -----"
  nvim --headless -u "$CONFIG/init.lua" -c "luafile $it"
  code=$?
  echo "exit code: $code"
  if [ "$code" -ne 0 ]; then spec_rc=1; fi
done
echo "specs exit code: $spec_rc"

section "update.sh (idempotency)"
bash "$CONFIG/update.sh" --yes || echo "WARN: update.sh returned non-zero"

section "result"
if [ "$spec_rc" -eq 0 ]; then
  echo "PASS: all specs green"
else
  echo "FAIL: specs exit $spec_rc"
fi
exit "$spec_rc"
