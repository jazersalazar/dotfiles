# Dotfiles

Personal development environment configuration for Windows 11 + WSL2 Ubuntu.

This repository contains my shell, terminal, editor, and CLI configuration so the development environment can be reproduced on a new machine.

## Environment

Primary environment:

- Windows 11
- WSL2
- Ubuntu
- Bash
- Windows Terminal
- Git + GitHub CLI
- Docker Desktop with WSL2 integration

## Included

Configuration for:

- Bash
- Starship
- tmux
- Neovim / LazyVim
- LazyGit

## Structure

```text
dotfiles/
├── bash/
│   ├── bashrc
│   └── bash_aliases
│
├── lazygit/
│   └── config.yml
│
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lazyvim.json
│   ├── lua/
│   └── ...
│
├── starship/
│   └── starship.toml
│
├── tmux/
│   └── tmux.conf
│
├── .gitignore
├── install.sh
└── README.md
```

## Install

Clone the repository:

```bash
git clone git@github.com:jazersalazar/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Run the installer:

```bash
./install.sh
```

The installer creates symlinks from this repository to the appropriate locations in `$HOME`.

Existing configuration files are backed up with a `.backup` suffix before being replaced.

## Configuration Locations

The repository manages the following configuration:

```text
~/dotfiles/bash/bashrc
    -> ~/.bashrc

~/dotfiles/bash/bash_aliases
    -> ~/.bash_aliases

~/dotfiles/starship/starship.toml
    -> ~/.config/starship.toml

~/dotfiles/tmux/tmux.conf
    -> ~/.tmux.conf

~/dotfiles/nvim
    -> ~/.config/nvim

~/dotfiles/lazygit/config.yml
    -> ~/.config/lazygit/config.yml
```

## Development Tools

The wider development environment currently includes tools such as:

### JavaScript / TypeScript

- Node.js
- npm
- pnpm

### Python

- Python
- uv

### Containers

- Docker
- Docker Compose

### Other Languages

- Go
- Rust
- Cargo

Additional language runtimes and tools can be installed as needed rather than being managed directly by this repository.

## GitHub

GitHub access is configured using:

- Git
- GitHub CLI (`gh`)
- SSH authentication

SSH keys and GitHub authentication credentials are **not stored in this repository**.

## Secrets

This repository must never contain:

- SSH private keys
- GitHub authentication tokens
- API keys
- passwords
- `.env` files
- project secrets
- shell history
- application credentials

Project-specific environment variables should remain inside their respective projects and should not be added to this repository.

## Purpose

The goal of this repository is to make the core development environment reproducible while keeping project-specific configuration separate.

The general setup is:

```text
Windows 11
    ↓
WSL2 / Ubuntu
    ↓
Shell + CLI environment
    ↓
Git / GitHub
    ↓
Docker
    ↓
Language runtimes
    ↓
Project-specific environments
```

This repository manages the shell and CLI configuration layer, not individual project dependencies.
