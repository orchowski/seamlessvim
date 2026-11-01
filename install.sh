#!/usr/bin/env bash
#
# seamlessvim installer: system tools + language runtimes + this config.
#
#   ./install.sh              # interactive
#   ./install.sh --yes        # non-interactive (CI, docker, provisioning)
#   ./install.sh --no-fonts   # skip Nerd Font installation
#
# Env:
#   SEAMLESSVIM_SOURCE=/path  install the config from a local checkout instead
#                             of cloning from GitHub
#
# Supported: Arch (pacman), Debian/Ubuntu (apt), macOS (brew).

set -euo pipefail

ASSUME_YES="${SEAMLESSVIM_ASSUME_YES:-0}"
WITH_FONTS=1
SOURCE_DIR="${SEAMLESSVIM_SOURCE:-}"
REPO_URL="${SEAMLESSVIM_REPO:-https://github.com/orchowski/seamlessvim.git}"
CONFIG_DIR="${SEAMLESSVIM_TARGET:-$HOME/.config/nvim}"

for arg in "$@"; do
  case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    --no-fonts) WITH_FONTS=0 ;;
    -h | --help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
  echo "+ $*"
  if [ "$ASSUME_YES" = 1 ]; then
    "$@" </dev/null
  else
    "$@"
  fi
}

# ----------------------------------------------------------------- platform --
if [ "$(uname)" = "Darwin" ]; then
  PM=brew
elif have pacman; then
  PM=pacman
elif have apt-get; then
  PM=apt
else
  echo "Unsupported platform: need pacman, apt-get or brew." >&2
  exit 1
fi
log "package manager: $PM"

install_pkg() {
  case "$PM" in
    brew) run brew install "$@" ;;
    pacman) run sudo pacman -S --needed --noconfirm "$@" ;;
    apt)
      run sudo apt-get update -qq
      run sudo apt-get install -y "$@"
      ;;
  esac
}

# --------------------------------------------------------------- base tools --
log "base tools (git, build tools, search tools)"
case "$PM" in
  brew)
    install_pkg git make gcc unzip curl ripgrep fd fzf coreutils
    ;;
  pacman)
    install_pkg git base-devel unzip curl ripgrep fd fzf
    ;;
  apt)
    install_pkg git build-essential unzip curl ripgrep fd-find fzf xz-utils
    # Debian ships fd-find and an ancient neovim; fix fd naming below.
    if have fdfind && ! have fd; then
      run sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
    ;;
esac

# ------------------------------------------------------------------- neovim --
NEED_NVIM=1
if have nvim; then
  NVIM_VER=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [ "$(printf '%s\n' "0.11" "$NVIM_VER" | sort -V | head -1)" = "0.11" ]; then
    NEED_NVIM=0
    log "neovim $NVIM_VER ok"
  else
    log "neovim $NVIM_VER too old (< 0.11), replacing"
  fi
fi
if [ "$NEED_NVIM" = 1 ]; then
  case "$PM" in
    brew) install_pkg neovim ;;
    pacman) install_pkg neovim ;;
    apt)
      # Debian/Ubuntu packages lag badly; install the official release tarball.
      log "installing neovim from GitHub releases"
      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64) NVIM_ARCH=x86_64 ;;
        aarch64 | arm64) NVIM_ARCH=arm64 ;;
        *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
      esac
      TMPD=$(mktemp -d)
      run curl -fsSL -o "$TMPD/nvim.tar.gz" "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${NVIM_ARCH}.tar.gz"
      run sudo rm -rf /opt/nvim
      run sudo tar -C /opt -xzf "$TMPD/nvim.tar.gz"
      run sudo ln -sf /opt/nvim-linux-${NVIM_ARCH}/bin/nvim /usr/local/bin/nvim
      rm -rf "$TMPD"
      ;;
  esac
fi

# --------------------------------------------------------- language runtimes --
log "language runtimes (JVM, Go, PHP, Python, Node)"
case "$PM" in
  brew)
    install_pkg openjdk go php composer python node
    run brew link --force --overwrite openjdk || true
    ;;
  pacman)
    install_pkg jdk-openjdk go php composer python python-pip nodejs npm
    ;;
  apt)
    install_pkg openjdk-25-jdk-headless golang-go php-cli php-xml php-mbstring php-curl php-zip composer python3 python3-venv python3-pip nodejs npm rlwrap
    ;;
esac

# Java on macOS: make sure `java` resolves.
if [ "$PM" = "brew" ] && ! have java; then
  run sudo ln -sfn "$(brew --prefix openjdk)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk || true
fi

# Arch: make the newest installed JDK the default (jdtls requires Java >= 25).
if [ "$PM" = "pacman" ] && have archlinux-java; then
  latest_jdk=$(archlinux-java status 2>/dev/null | awk '/^  java-/{print $1}' | sort -V | tail -1)
  if [ -n "$latest_jdk" ]; then
    run sudo archlinux-java set "$latest_jdk"
  fi
fi

# Clojure CLI (clojure-lsp computes the classpath from deps.edn/project.clj).
# Debian's `clojure` package is only a REPL launcher (no `-Spath`), so use the
# official Clojure CLI tools there.
log "Clojure CLI"
case "$PM" in
  brew) run brew install clojure || echo "clojure CLI install failed (optional)" ;;
  pacman) run sudo pacman -S --needed --noconfirm clojure || echo "clojure CLI install failed (optional)" ;;
  apt)
    run curl -fsSL -o /tmp/clj-install.sh "https://download.clojure.org/install/linux-install-${CLOJURE_CLI_VERSION:-1.12.0.1530}.sh"
    run sudo bash /tmp/clj-install.sh || echo "clojure CLI install failed (optional)"
    ;;
esac

# Arch builds PHP's iconv as a shared extension that is not enabled by default;
# phpactor's phar refuses to start without it.
if [ "$PM" = "pacman" ] && have php && ! php -r 'exit(function_exists("iconv") ? 0 : 1);' 2>/dev/null; then
  log "enabling PHP iconv extension (needed by phpactor)"
  echo 'extension=iconv' | sudo tee /etc/php/conf.d/iconv.ini >/dev/null
fi

# Delve (Go debugger) requires a recent Go toolchain; distro packages can lag.
GO_VER=""
if have go; then
  GO_VER=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | head -1 | sed 's/^go//')
fi
if [ -z "$GO_VER" ] || [ "$(printf '%s\n' "1.25" "$GO_VER" | sort -V | head -1)" != "1.25" ]; then
  log "installing recent Go toolchain (needed by delve)"
  GO_LATEST=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)
  case "$(uname -m)" in
    x86_64) GO_ARCH=amd64 ;;
    aarch64 | arm64) GO_ARCH=arm64 ;;
    *) GO_ARCH="" ;;
  esac
  if [ -n "$GO_ARCH" ] && [ -n "$GO_LATEST" ]; then
    run curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/${GO_LATEST}.linux-${GO_ARCH}.tar.gz"
    run sudo rm -rf /usr/local/go
    run sudo tar -C /usr/local -xzf /tmp/go.tgz
    run sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    run sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  fi
fi

# ------------------------------------------------------------- tree-sitter --
log "tree-sitter CLI (>= 0.26 for nvim-treesitter main branch)"
TS_OK=0
if have tree-sitter; then
  TS_VER=$(tree-sitter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -n "$TS_VER" ] && [ "$(printf '%s\n' "0.26.0" "$TS_VER" | sort -V | head -1)" = "0.26.0" ]; then
    TS_OK=1
    log "tree-sitter $TS_VER ok"
  fi
fi
if [ "$TS_OK" = 0 ]; then
  case "$PM" in
    brew) install_pkg tree-sitter ;;
    pacman) install_pkg tree-sitter-cli ;;
    apt)
      # Debian's package is too old; use the upstream static binary.
      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64) TS_ARCH=x64 ;;
        aarch64 | arm64) TS_ARCH=arm64 ;;
        *) TS_ARCH="" ;;
      esac
      if [ -n "$TS_ARCH" ]; then
        run curl -fsSL -o /tmp/tree-sitter.gz "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${TS_ARCH}.gz"
        run gzip -df /tmp/tree-sitter.gz
        run sudo install -m 755 /tmp/tree-sitter /usr/local/bin/tree-sitter
      fi
      ;;
  esac
fi

# ---------------------------------------------------------------- coursier --
log "coursier (for metals/scalafmt - Scala)"
if ! have cs; then
  case "$(uname)-$(uname -m)" in
    Darwin-x86_64) CS_PKG=cs-x86_64-apple-darwin.gz ;;
    Darwin-arm64) CS_PKG=cs-aarch64-apple-darwin.gz ;;
    Linux-x86_64) CS_PKG=cs-x86_64-pc-linux.gz ;;
    Linux-aarch64) CS_PKG=cs-aarch64-pc-linux.gz ;;
    *) CS_PKG="" ;;
  esac
  if [ -n "$CS_PKG" ]; then
    run mkdir -p "$HOME/.local/bin"
    run curl -fsSL -o /tmp/cs.gz "https://github.com/coursier/coursier/releases/latest/download/$CS_PKG"
    run gzip -df /tmp/cs.gz
    run install -m 755 /tmp/cs "$HOME/.local/bin/cs"
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi
if have cs; then
  run cs install metals scalafmt || echo "coursier install failed (metals optional)"
fi

# ------------------------------------------------------------------- fonts --
if [ "$WITH_FONTS" = 1 ] && [ "$PM" = "brew" ]; then
  log "Nerd Font (JetBrains Mono)"
  run brew install --cask font-jetbrains-mono-nerd-font || echo "font install failed (optional)"
elif [ "$WITH_FONTS" = 1 ]; then
  log "Nerd Font (JetBrains Mono) -> ~/.local/share/fonts"
  mkdir -p "$HOME/.local/share/fonts"
  run curl -fsSL -o /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" || true
  if [ -f /tmp/JetBrainsMono.zip ]; then
    run unzip -oq /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts" || true
    rm -f /tmp/JetBrainsMono.zip
    if have fc-cache; then
      run fc-cache -f "$HOME/.local/share/fonts" || true
    fi
  fi
fi

# ------------------------------------------------------------------ config --
log "installing seamlessvim -> $CONFIG_DIR"
if [ -d "$CONFIG_DIR" ] && [ "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
  BACKUP="$CONFIG_DIR-$(date +%Y%m%d%H%M%S).tar.gz"
  log "backing up existing config to $BACKUP"
  run tar -czf "$BACKUP" -C "$(dirname "$CONFIG_DIR")" "$(basename "$CONFIG_DIR")"
  run rm -rf "$CONFIG_DIR"
fi

if [ -n "$SOURCE_DIR" ]; then
  run mkdir -p "$CONFIG_DIR"
  run cp -a "$SOURCE_DIR/." "$CONFIG_DIR/"
else
  run git clone "$REPO_URL" "$CONFIG_DIR"
fi

# -------------------------------------------------------------- bootstrap --
log "bootstrapping neovim (lazy.nvim, plugins, LSP/debug tools)"
export PATH="$HOME/.local/bin:$PATH"
run nvim --headless "+Lazy! sync" "+qa" || true
# mason-tool-installer auto-runs on startup; give it a sync pass for scripts.
run nvim --headless "+MasonToolsInstallSync" "+qa" || true
# treesitter parsers
run nvim --headless "+lua require('nvim-treesitter').install(require('config.parsers')):wait(600000)" "+qa" || true

log "done. Start with: nvim"
echo
echo "Notes:"
echo "  * Update everything on this machine:  $CONFIG_DIR/update.sh"
echo "  * Scala metals/scalafmt live in ~/.local/share/coursier/bin (or ~/.local/bin)."
echo "  * Java debugging/testing bundles come from mason (java-debug-adapter, java-test)."
