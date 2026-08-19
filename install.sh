#!/usr/bin/env bash

set -euo pipefail

INSTALL_CODEX=""
INSTALL_CLAUDE=""
INSTALL_GO=""
INSTALL_RUST=""
INSTALL_JAVA=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Options:
  --with-codex      Install Codex CLI without prompting
  --without-codex   Skip installing Codex CLI
  --with-claude     Install Claude Code without prompting
  --without-claude  Skip installing Claude Code
  --with-go         Install Go without prompting
  --without-go      Skip installing Go
  --with-rust       Install Rust without prompting
  --without-rust    Skip installing Rust
  --with-java       Install Java without prompting
  --without-java    Skip installing Java
  -h, --help        Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-codex)
      INSTALL_CODEX=true
      ;;
    --without-codex)
      INSTALL_CODEX=false
      ;;
    --with-claude)
      INSTALL_CLAUDE=true
      ;;
    --without-claude)
      INSTALL_CLAUDE=false
      ;;
    --with-go)
      INSTALL_GO=true
      ;;
    --without-go)
      INSTALL_GO=false
      ;;
    --with-rust)
      INSTALL_RUST=true
      ;;
    --without-rust)
      INSTALL_RUST=false
      ;;
    --with-java)
      INSTALL_JAVA=true
      ;;
    --without-java)
      INSTALL_JAVA=false
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

choose_optional_tool() {
  local tool_name="$1"
  local reply

  if [ ! -t 0 ]; then
    printf 'true'
    return
  fi

  read -r -p "Install $tool_name? [Y/n] " reply || reply=""
  case "$reply" in
    n | N | no | NO | No)
      printf 'false'
      ;;
    *)
      printf 'true'
      ;;
  esac
}

if [ -z "$INSTALL_CODEX" ]; then
  INSTALL_CODEX="$(choose_optional_tool "Codex CLI")"
fi

if [ -z "$INSTALL_CLAUDE" ]; then
  INSTALL_CLAUDE="$(choose_optional_tool "Claude Code")"
fi

if [ -z "$INSTALL_GO" ]; then
  INSTALL_GO="$(choose_optional_tool "Go")"
fi

if [ -z "$INSTALL_RUST" ]; then
  INSTALL_RUST="$(choose_optional_tool "Rust")"
fi

if [ -z "$INSTALL_JAVA" ]; then
  INSTALL_JAVA="$(choose_optional_tool "Java")"
fi

echo "======================================"
echo "  WSL Development Environment Setup"
echo "======================================"
echo

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Error: This install script requires Linux/WSL."
  exit 1
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "✓ WSL detected"
else
  echo "Warning: WSL was not detected."
fi

echo
echo "Updating package index..."

sudo apt update

echo
echo "Installing base packages..."

sudo apt install -y \
  build-essential \
  ca-certificates \
  curl \
  wget \
  python3 \
  python3-venv \
  postgresql-client \
  unzip \
  zip \
  git \
  tmux \
  ripgrep \
  fd-find \
  fzf \
  bat \
  eza \
  jq \
  zoxide \
  htop \
  btop \
  tree \
  make \
  gcc \
  g++ \
  cmake \
  pkg-config

echo
echo "Base packages installed."

# Ubuntu packages expose fd and bat as fdfind and batcat on some releases.
mkdir -p "$HOME/.local/bin"

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# ------------------------------------------------------------
# Node.js / fnm
# ------------------------------------------------------------

echo
echo "Setting up Node.js..."

FNM_DIR="$HOME/.local/share/fnm"

if [ ! -x "$FNM_DIR/fnm" ]; then
  echo "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

export PATH="$FNM_DIR:$PATH"

eval "$(fnm env --shell bash)"

fnm install --lts
fnm use lts-latest
fnm default lts-latest

echo "Node: $(node --version)"
echo "NPM:  $(npm --version)"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "Installing pnpm..."
  npm install --global pnpm
fi

echo "pnpm: $(pnpm --version)"

if ! command -v tsx >/dev/null 2>&1; then
  echo "Installing tsx..."
  npm install --global tsx
fi

echo "tsx:  $(tsx --version | head -n 1)"

# ------------------------------------------------------------
# Python / uv
# ------------------------------------------------------------

echo
echo "Setting up Python and uv..."

export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "uv: $(uv --version)"
echo "Python: $(python3 --version)"

# ------------------------------------------------------------
# Go
# ------------------------------------------------------------

echo
echo "Setting up Go..."

if [ "$INSTALL_GO" = true ]; then
  if ! command -v go >/dev/null 2>&1; then
    echo "Installing Go..."
    sudo apt-get install -y golang-go
  fi

  echo "Go: $(go version)"
  echo "GOROOT: $(go env GOROOT)"
  echo "GOPATH: $(go env GOPATH)"
else
  echo "Skipping Go."
fi

# ------------------------------------------------------------
# Rust / rustup
# ------------------------------------------------------------

echo
echo "Setting up Rust..."

export PATH="$HOME/.cargo/bin:$PATH"

if [ "$INSTALL_RUST" = true ]; then
  if ! command -v rustup >/dev/null 2>&1; then
    echo "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  rustup default stable

  echo "Rust: $(rustc --version)"
  echo "Cargo: $(cargo --version)"
  echo "Toolchain: $(rustup show active-toolchain)"
else
  echo "Skipping Rust."
fi

# ------------------------------------------------------------
# Java
# ------------------------------------------------------------

echo
echo "Setting up Java..."

if [ "$INSTALL_JAVA" = true ]; then
  if ! command -v java >/dev/null 2>&1 || ! command -v javac >/dev/null 2>&1; then
    echo "Installing OpenJDK..."
    sudo apt-get install -y default-jdk
  fi

  echo "Java: $(java -version 2>&1 | head -n 1)"
  echo "Javac: $(javac -version 2>&1)"
else
  echo "Skipping Java."
fi

# ------------------------------------------------------------
# GitHub CLI
# ------------------------------------------------------------

echo
echo "Setting up GitHub CLI..."

if ! command -v gh >/dev/null 2>&1; then
  echo "Installing GitHub CLI..."

  sudo mkdir -p -m 755 /etc/apt/keyrings

  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null

  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y gh
fi

echo "GitHub CLI: $(gh --version | head -n 1)"

# ------------------------------------------------------------
# Codex CLI
# ------------------------------------------------------------

echo
if [ "$INSTALL_CODEX" = true ]; then
  echo "Setting up Codex CLI..."

  if ! command -v codex >/dev/null 2>&1; then
    echo "Installing Codex CLI..."
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
    hash -r
  fi

  echo "Codex CLI: $(codex --version)"
else
  echo "Skipping Codex CLI."
fi

# ------------------------------------------------------------
# Claude Code
# ------------------------------------------------------------

echo
if [ "$INSTALL_CLAUDE" = true ]; then
  echo "Setting up Claude Code..."

  if ! command -v claude >/dev/null 2>&1; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    hash -r
  fi

  echo "Claude Code: $(claude --version)"
else
  echo "Skipping Claude Code."
fi

# ------------------------------------------------------------
# Neovim
# ------------------------------------------------------------

echo
echo "Setting up Neovim..."

if ! command -v nvim >/dev/null 2>&1; then
  echo "Installing Neovim..."

  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

  rm nvim-linux-x86_64.tar.gz

  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
fi

echo "Neovim: $(nvim --version | head -n 1)"

# ------------------------------------------------------------
# Lazygit
# ------------------------------------------------------------

echo
echo "Setting up Lazygit..."

LAZYGIT_VERSION="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*' || true)"
LAZYGIT_ARCH="$(uname -m | sed -e 's/aarch64/arm64/')"
LAZYGIT_INSTALLED_VERSION=""

if command -v lazygit >/dev/null 2>&1; then
  LAZYGIT_INSTALLED_VERSION="$(lazygit --version | grep -oP "(?<=, version=)'?[^,']+" | tr -d "'" || true)"
fi

# The release lookup is unauthenticated, so it comes back empty on GitHub's
# hourly API rate limit or with no network. Under `set -e` that used to abort the
# whole install partway through, before the dotfiles were ever linked, so treat
# it as "cannot check for an upgrade" and carry on.
if [ -z "$LAZYGIT_VERSION" ]; then
  echo "Skipping Lazygit: could not read the latest release from GitHub."
elif [ "$LAZYGIT_INSTALLED_VERSION" != "$LAZYGIT_VERSION" ]; then
  if [ -n "$LAZYGIT_INSTALLED_VERSION" ]; then
    echo "Upgrading Lazygit: $LAZYGIT_INSTALLED_VERSION -> $LAZYGIT_VERSION"
  else
    echo "Installing Lazygit..."
  fi

  (
    LAZYGIT_TMP="$(mktemp -d)"

    trap 'rm -rf "$LAZYGIT_TMP"' EXIT

    curl -fsSL -o "$LAZYGIT_TMP/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"

    tar -xzf "$LAZYGIT_TMP/lazygit.tar.gz" -C "$LAZYGIT_TMP" lazygit
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$LAZYGIT_TMP/lazygit" "$HOME/.local/bin/lazygit"
  )

  hash -r
else
  echo "Lazygit is already up to date."
fi

if command -v lazygit >/dev/null 2>&1; then
  echo "Lazygit: $(lazygit --version)"
fi

# ------------------------------------------------------------
# Starship
# ------------------------------------------------------------

echo
echo "Setting up Starship..."

if ! command -v starship >/dev/null 2>&1; then
  echo "Installing Starship..."

  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

echo "Starship: $(starship --version | head -n 1)"

# ------------------------------------------------------------
# Docker Desktop / WSL integration
# ------------------------------------------------------------

echo
echo "Checking Docker..."

DOCKER_VERSION="Not available"

if command -v docker >/dev/null 2>&1; then
  if DOCKER_VERSION="$(docker --version 2>/dev/null)"; then
    echo "Docker:   $DOCKER_VERSION"

    if docker info >/dev/null 2>&1; then
      echo "✓ Docker daemon reachable"
    else
      echo "Warning: Docker CLI exists but the daemon is unavailable."
      echo "Start Docker Desktop and enable WSL integration for this distro."
    fi
  else
    DOCKER_VERSION="Not available"
    echo "Docker is installed on Windows but unavailable in this WSL distro."
    echo "Enable Docker Desktop WSL integration for this distro."
  fi
else
  echo "Docker is not available inside WSL."
  echo "Install Docker Desktop on Windows and enable WSL integration."
fi

# ------------------------------------------------------------
# Dotfiles
# ------------------------------------------------------------

echo
echo "Installing dotfiles..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/link-dotfiles.sh"

# ------------------------------------------------------------
# tmux plugins
# ------------------------------------------------------------

echo
echo "Setting up tmux plugins..."

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -x "$TPM_DIR/bin/install_plugins" ]; then
  if [ -e "$TPM_DIR" ] || [ -L "$TPM_DIR" ]; then
    echo "Error: $TPM_DIR exists but is not a valid TPM installation."
    exit 1
  fi

  echo "Installing Tmux Plugin Manager..."
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

"$TPM_DIR/bin/install_plugins"

echo
echo "========================================"
echo "  Development environment ready!"
echo "========================================"
echo
echo "Node:     $(node --version)"
echo "pnpm:     $(pnpm --version)"
echo "tsx:      $(tsx --version | head -n 1)"
echo "Postgres: $(psql --version)"
echo "Python:   $(python3 --version)"
echo "uv:       $(uv --version)"
echo "GitHub:   $(gh --version | head -n 1)"
if [ "$INSTALL_CODEX" = true ]; then
  echo "Codex:    $(codex --version)"
fi
if [ "$INSTALL_CLAUDE" = true ]; then
  echo "Claude:   $(claude --version)"
fi
if [ "$INSTALL_GO" = true ]; then
  echo "Go:       $(go version)"
fi
if [ "$INSTALL_RUST" = true ]; then
  echo "Rust:     $(rustc --version)"
fi
if [ "$INSTALL_JAVA" = true ]; then
  echo "Java:     $(java -version 2>&1 | head -n 1)"
fi
echo "Neovim:   $(nvim --version | head -n 1)"
echo "Lazygit:  $(lazygit --version)"
echo "Starship: $(starship --version | head -n 1)"
echo "Docker:   $DOCKER_VERSION"
echo
echo "Restart your terminal to ensure all shell configuration is loaded."
