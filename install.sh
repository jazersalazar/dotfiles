#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from: $DOTFILES"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/lazygit"

link() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up $target -> ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    ln -sfn "$source" "$target"
    echo "Linked $target"
}

link "$DOTFILES/bash/bashrc" "$HOME/.bashrc"
link "$DOTFILES/bash/bash_aliases" "$HOME/.bash_aliases"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/nvim" "$HOME/.config/nvim"
link "$DOTFILES/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

echo
echo "Dotfiles installed."
