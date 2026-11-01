#!/usr/bin/env bash
#
# Prepares language fixtures that need generated/ignored files:
#   * python  -> .venv with pytest (neotest-python is pointed at .venv/bin/python)
#   * php     -> composer install (vendor/bin/phpunit)
#   * groovy  -> Jenkinsfile root marker (kept out of git via generation here)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -x "$ROOT/python/.venv/bin/python" ]; then
  echo "preparing python venv"
  python3 -m venv "$ROOT/python/.venv"
  "$ROOT/python/.venv/bin/pip" install --quiet --upgrade pip
  "$ROOT/python/.venv/bin/pip" install --quiet pytest
fi

if [ ! -x "$ROOT/php/vendor/bin/phpunit" ]; then
  echo "preparing php deps (composer install)"
  ( cd "$ROOT/php" && composer install --no-interaction --quiet --no-progress )
fi

# groovyls' root marker (see lspconfig groovyls: {Jenkinsfile, .git})
touch "$ROOT/groovy/Jenkinsfile"

# Warm the Clojure CLI deps so clojure-lsp's `clojure -Spath` resolves instantly
# (otherwise its first run downloads deps and stalls the LSP handshake).
if command -v clojure >/dev/null 2>&1; then
  echo "warming clojure deps"
  ( cd "$ROOT/clojure" && clojure -Spath >/dev/null 2>&1 ) || true
fi

echo "fixtures ready"
