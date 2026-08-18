#!/usr/bin/env bash

set -euo pipefail

echo "======================================"
echo "  WSL Development Environment Setup"
echo "======================================"
echo

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Error: This bootstrap script requires Linux/WSL."
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

# ------------------------------------------------------------
# Python / uv
# ------------------------------------------------------------

echo
echo "Setting up Python and uv..."

if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"

echo "uv: $(uv --version)"
echo "Python: $(python3 --version)"

# ------------------------------------------------------------
# Go
# ------------------------------------------------------------

echo
echo "Setting up Go..."

if ! command -v go >/dev/null 2>&1; then
  echo "Installing Go..."
  sudo apt-get install -y golang-go
fi

echo "Go: $(go version)"
echo "GOROOT: $(go env GOROOT)"
echo "GOPATH: $(go env GOPATH)"

# ------------------------------------------------------------
# Rust / rustup
# ------------------------------------------------------------

echo
echo "Setting up Rust..."

if ! command -v rustup >/dev/null 2>&1; then
  echo "Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

export PATH="$HOME/.cargo/bin:$PATH"

rustup default stable

echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Toolchain: $(rustup show active-toolchain)"

# ------------------------------------------------------------
# Java
# ------------------------------------------------------------

echo
echo "Setting up Java..."

if ! command -v java >/dev/null 2>&1 || ! command -v javac >/dev/null 2>&1; then
  echo "Installing OpenJDK..."
  sudo apt-get install -y default-jdk
fi

echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Javac: $(javac -version 2>&1)"

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

LAZYGIT_VERSION="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')"
LAZYGIT_ARCH="$(uname -m | sed -e 's/aarch64/arm64/')"
LAZYGIT_INSTALLED_VERSION=""

if command -v lazygit >/dev/null 2>&1; then
  LAZYGIT_INSTALLED_VERSION="$(lazygit --version | grep -oP "(?<=, version=)'?[^,']+" | tr -d "'" || true)"
fi

if [ "$LAZYGIT_INSTALLED_VERSION" != "$LAZYGIT_VERSION" ]; then
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

echo "Lazygit: $(lazygit --version)"

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
  DOCKER_VERSION="$(docker --version)"
  echo "Docker:   $DOCKER_VERSION"

  if docker info >/dev/null 2>&1; then
    echo "✓ Docker daemon reachable"
  else
    echo "Warning: Docker CLI exists but the daemon is unavailable."
    echo "Start Docker Desktop and enable WSL integration for this distro."
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

"$SCRIPT_DIR/install.sh"

echo
echo "========================================"
echo "  Development environment ready!"
echo "========================================"
echo
echo "Node:     $(node --version)"
echo "pnpm:     $(pnpm --version)"
echo "Python:   $(python3 --version)"
echo "uv:       $(uv --version)"
echo "Go:       $(go version)"
echo "Rust:     $(rustc --version)"
echo "Java:     $(java -version 2>&1 | head -n 1)"
echo "GitHub:   $(gh --version | head -n 1)"
echo "Neovim:   $(nvim --version | head -n 1)"
echo "Lazygit:  $(lazygit --version)"
echo "Starship: $(starship --version | head -n 1)"
echo "Docker:   $DOCKER_VERSION"
echo
echo "Restart your terminal to ensure all shell configuration is loaded."
