#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from: $DOTFILES"
echo

link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  # Already linked correctly
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    echo "✓ Already linked: $target"
    return
  fi

  # Backup an existing real file/directory or incorrect symlink
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup
    backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up: $target -> $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  echo "✓ Linked: $target -> $source"
}

link "$DOTFILES/bash/bashrc" "$HOME/.bashrc"
link "$DOTFILES/bash/bash_aliases" "$HOME/.bash_aliases"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES/tmux/quote.sh" "$HOME/.tmux/quote.sh"
link "$DOTFILES/tmux/quote-rotate.sh" "$HOME/.tmux/quote-rotate.sh"
link "$DOTFILES/tmux/quotes.txt" "$HOME/.tmux/quotes.txt"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/nvim" "$HOME/.config/nvim"
link "$DOTFILES/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

echo
echo "Dotfiles installed successfully."
