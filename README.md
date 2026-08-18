# WSL Development Environment

Personal development environment and dotfiles for Ubuntu on WSL2.

This repository contains my shell configuration, development tools, and bootstrap scripts for rebuilding my WSL development environment.

## Environment

Primary environment:

- Windows 11
- WSL2
- Ubuntu
- Windows Terminal
- Docker Desktop with WSL integration

## Repository Structure

```text
dotfiles/
├── bash/
│   ├── bash_aliases
│   └── bashrc
├── lazygit/
│   └── config.yml
├── nvim/
│   ├── .gitignore
│   ├── .neoconf.json
│   ├── LICENSE
│   ├── README.md
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lazyvim.json
│   ├── lua/
│   │   ├── config/
│   │   │   ├── autocmds.lua
│   │   │   ├── keymaps.lua
│   │   │   ├── lazy.lua
│   │   │   └── options.lua
│   │   └── plugins/
│   │       ├── colorscheme.lua
│   │       ├── example.lua
│   │       └── tmux.lua
│   └── stylua.toml
├── starship/
│   └── starship.toml
├── tmux/
│   └── tmux.conf
├── .gitignore
├── bootstrap.sh
├── install.sh
└── README.md
```

## Scripts

### `bootstrap.sh`

Sets up the WSL development environment.

It handles:

- base Linux packages
- Node.js and pnpm
- Python and uv
- Go
- Rust
- Java
- GitHub CLI
- Neovim
- Starship
- Docker WSL integration checks
- dotfile installation

At the end, `bootstrap.sh` runs:

```bash
./install.sh
```

### `install.sh`

Creates symlinks between this repository and the corresponding configuration files in the home directory.

The installer is designed to be safe to run multiple times.

Existing real files or directories are backed up before they are replaced with symlinks.

## Configuration Mapping

```text
~/dotfiles/bash/bashrc
→ ~/.bashrc

~/dotfiles/bash/bash_aliases
→ ~/.bash_aliases

~/dotfiles/tmux/tmux.conf
→ ~/.tmux.conf

~/dotfiles/starship/starship.toml
→ ~/.config/starship.toml

~/dotfiles/nvim
→ ~/.config/nvim

~/dotfiles/lazygit/config.yml
→ ~/.config/lazygit/config.yml
```

## Development Tools

### Languages and Runtimes

- Node.js via `fnm`
- npm
- pnpm
- Python
- uv
- Go
- Rust via `rustup`
- Cargo
- Java / OpenJDK

### Development Tools

- Git
- GitHub CLI
- Docker CLI
- Neovim
- tmux
- lazygit
- Starship

### CLI Utilities

- ripgrep (`rg`)
- fd
- fzf
- bat
- eza
- jq
- zoxide
- curl
- wget
- unzip
- zip
- tree
- htop
- btop

### Build Tools

- build-essential
- make
- gcc
- g++
- cmake
- pkg-config

---

# Fresh Machine Setup

These instructions are intended for a new Windows and WSL installation.

If `~/dotfiles` already exists, do not clone the repository again.

## 1. Install WSL2

Open PowerShell as Administrator:

```powershell
wsl --install
```

Restart Windows if required.

Open Ubuntu and complete the initial Linux user setup.

Verify:

```bash
wsl.exe --status
```

From Ubuntu:

```bash
uname -a
```

## 2. Update Ubuntu

Inside Ubuntu:

```bash
sudo apt update
sudo apt upgrade
```

## 3. Configure Git

Install Git first if needed:

```bash
sudo apt install -y git
```

Configure your identity:

```bash
git config --global user.name "Jazer Salazar"
git config --global user.email "YOUR_GITHUB_EMAIL"
git config --global init.defaultBranch main
```

Verify:

```bash
git config --global user.name
git config --global user.email
git config --global init.defaultBranch
```

## 4. Configure GitHub SSH

Create the SSH directory if necessary:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Generate an SSH key:

```bash
ssh-keygen -t ed25519 -C "YOUR_GITHUB_EMAIL"
```

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
```

Add the key:

```bash
ssh-add ~/.ssh/id_ed25519
```

Display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add the public key to your GitHub account.

Test authentication:

```bash
ssh -T git@github.com
```

A successful connection may show:

```text
You've successfully authenticated, but GitHub does not provide shell access.
```

This is expected.

## 5. Clone the Dotfiles Repository

On a fresh WSL installation only:

```bash
cd ~
git clone git@github.com:jazersalazar/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 6. Run Bootstrap

Run:

```bash
./bootstrap.sh
```

The script installs and configures the development environment and then installs the dotfiles.

The script can also be rerun later to repair or update the environment.

## 7. Install Docker Desktop

Docker Desktop is installed on Windows, not directly by `bootstrap.sh`.

Install Docker Desktop and enable WSL integration for Ubuntu.

In Docker Desktop:

```text
Settings
→ Resources
→ WSL Integration
→ Ubuntu
```

Enable Ubuntu and apply the changes.

Then verify inside WSL:

```bash
docker --version
docker info
```

Test a container:

```bash
docker run --rm hello-world
```

## 8. Restart the Terminal

After bootstrap completes, close the Ubuntu terminal completely and open a new one.

This ensures shell configuration and PATH changes are loaded correctly.

---

# Verification

## Development Runtimes

Run:

```bash
node --version
pnpm --version
python3 --version
uv --version
go version
rustc --version
cargo --version
java -version
gh --version
nvim --version
starship --version
docker --version
```

## CLI Tools

Run:

```bash
for cmd in git gh nvim tmux lazygit starship rg fd fzf bat eza jq zoxide curl wget make gcc g++ cmake docker; do
    printf "%-12s " "$cmd"
    command -v "$cmd" || echo "NOT FOUND"
done
```

Every command should resolve to an executable path.

## GitHub CLI

Check GitHub authentication:

```bash
gh auth status
```

## GitHub SSH

Check SSH authentication:

```bash
ssh -T git@github.com
```

## Docker

Check the Docker daemon:

```bash
docker info >/dev/null && echo "Docker daemon reachable"
```

Run a container:

```bash
docker run --rm hello-world >/dev/null && echo "Docker containers working"
```

## Dotfiles

Check the repository:

```bash
cd ~/dotfiles
git status
```

Expected result:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

# Development Directory Structure

Keep source code inside the WSL Linux filesystem where possible.

Recommended structure:

```text
~
├── dotfiles/
└── projects/
    ├── project-a/
    ├── project-b/
    └── project-c/
```

Create the projects directory:

```bash
mkdir -p ~/projects
```

Clone projects into it:

```bash
cd ~/projects
git clone git@github.com:USERNAME/PROJECT.git
```

Keeping development projects inside `~/projects` avoids unnecessary Windows and Linux filesystem boundary issues.

---

# Dotfiles Workflow

Because the configuration files are symlinked, editing files such as:

```text
~/.bashrc
~/.tmux.conf
~/.config/starship.toml
```

also modifies the corresponding files inside the dotfiles repository.

For example:

```text
~/.bashrc
→ ~/dotfiles/bash/bashrc
```

## Check Changes

```bash
cd ~/dotfiles
git status
git diff
```

## Validate Shell Scripts

For `bootstrap.sh`:

```bash
bash -n bootstrap.sh
```

For `install.sh`:

```bash
bash -n install.sh
```

## Stage Changes

```bash
git add .
```

## Review Staged Changes

```bash
git diff --cached
```

Check for whitespace issues:

```bash
git diff --cached --check
```

## Commit

```bash
git commit -m "Describe the change"
```

## Push

```bash
git push
```

## Verify

```bash
git status
```

Expected:

```text
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

# Updating the Development Environment

Pull the latest dotfiles:

```bash
cd ~/dotfiles
git pull
```

Rerun the bootstrap:

```bash
./bootstrap.sh
```

Restart the terminal afterward if shell configuration or PATH-related settings changed.

---

# Node.js

Node.js is managed using `fnm`.

Check the current version:

```bash
fnm current
```

List installed versions:

```bash
fnm list
```

Install the latest LTS:

```bash
fnm install --lts
```

Use the latest LTS:

```bash
fnm use lts-latest
```

Set it as the default:

```bash
fnm default lts-latest
```

---

# Python

Python project environments are managed using `uv`.

Create a project:

```bash
mkdir my-python-project
cd my-python-project
uv init
```

Create a virtual environment:

```bash
uv venv
```

Activate it:

```bash
source .venv/bin/activate
```

Add packages:

```bash
uv add PACKAGE_NAME
```

---

# Rust

Rust is managed using `rustup`.

Check the active toolchain:

```bash
rustup show active-toolchain
```

Update Rust:

```bash
rustup update
```

---

# Go

Check the Go environment:

```bash
go version
go env GOROOT
go env GOPATH
```

Projects can be stored normally under:

```text
~/projects
```

Go modules do not need to live inside `GOPATH`.

---

# Docker

Docker Desktop provides the Docker daemon through WSL integration.

Useful commands:

```bash
docker ps
docker images
docker compose version
docker info
```

Run a test container:

```bash
docker run --rm hello-world
```

If Docker disappears from WSL, verify Docker Desktop is running and confirm Ubuntu is enabled under Docker Desktop's WSL integration settings.

---

# Neovim

Neovim configuration is stored in:

```text
~/dotfiles/nvim
```

and linked to:

```text
~/.config/nvim
```

Open Neovim:

```bash
nvim
```

Check the installed version:

```bash
nvim --version
```

---

# tmux

tmux configuration is stored in:

```text
~/dotfiles/tmux/tmux.conf
```

and linked to:

```text
~/.tmux.conf
```

Start tmux:

```bash
tmux
```

Check version:

```bash
tmux -V
```

---

# Lazygit

Lazygit configuration is stored in:

```text
~/dotfiles/lazygit/config.yml
```

and linked to:

```text
~/.config/lazygit/config.yml
```

Launch:

```bash
lazygit
```

---

# Starship

Starship configuration is stored in:

```text
~/dotfiles/starship/starship.toml
```

and linked to:

```text
~/.config/starship.toml
```

Check version:

```bash
starship --version
```

---

# Secrets

Never commit secrets to this repository.

Do not commit:

- `.env`
- `.env.local`
- API keys
- access tokens
- GitHub authentication tokens
- SSH private keys
- passwords
- database credentials
- project secrets

SSH private keys should remain under:

```text
~/.ssh/
```

Project environment variables should remain inside their respective project directories and should be excluded through `.gitignore`.

---

# Notes

- The environment is designed primarily for Ubuntu under WSL2.
- `bootstrap.sh` installs and configures the development environment.
- `install.sh` manages the dotfile symlinks.
- Docker Desktop remains a Windows-side dependency.
- Node.js is managed using `fnm`.
- Python tooling uses `uv`.
- Rust is managed using `rustup`.
- Development projects should generally live under `~/projects`.
- Dotfiles are symlinked rather than copied.
- Secrets must never be committed to this repository.
