# WSL Development Environment

Dotfiles and setup scripts for a development environment running Ubuntu on WSL2.

The installer installs the command-line tools and language runtimes used by this environment, then links the repository configuration into the home directory.

## What Gets Installed

- Node.js via `fnm`, npm, and pnpm
- Python and `uv`
- Optional Go, Rust via `rustup`, and Java / OpenJDK
- Git and GitHub CLI
- Optional AI coding tools: OpenAI Codex CLI and Claude Code
- Neovim, tmux with automatic session persistence, Lazygit, and Starship
- ShellCheck for linting the shell scripts in this repository
- JavaScript, TypeScript, and Python debugging with `nvim-dap`, `js-debug-adapter`, `debugpy`, and `tsx`
- PostgreSQL client tools and Neovim SQL support with Dadbod
- CLI and build tools such as `rg`, `fd`, `fzf`, `bat`, `eza`, `jq`, `zoxide`, and GCC

Docker is provided separately by Docker Desktop for Windows with WSL integration enabled.

# Setup Guide

These steps are intended for a fresh Windows and Ubuntu on WSL installation. If `~/dotfiles` already exists, skip the clone step and use the update instructions below.

## 1. Install WSL2

Open PowerShell as Administrator:

```powershell
wsl --install
```

Restart Windows if requested, open Ubuntu, and complete the initial Linux user setup.

Verify WSL from PowerShell:

```powershell
wsl --status
```

## 2. Update Ubuntu

Inside Ubuntu:

```bash
sudo apt update
sudo apt upgrade -y
```

## 3. Configure Git

Install Git:

```bash
sudo apt install -y git
```

Configure your identity, replacing the placeholders with the name and email address associated with your GitHub identity:

```bash
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_GITHUB_EMAIL"
git config --global init.defaultBranch main
```

## 4. Configure GitHub SSH

Generate an SSH key:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "YOUR_GITHUB_EMAIL"
```

Start the SSH agent and add the key:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Copy the public key and add it to your GitHub account:

```bash
cat ~/.ssh/id_ed25519.pub
```

Test authentication:

```bash
ssh -T git@github.com
```

GitHub may report that it does not provide shell access after confirming successful authentication. This is expected.

## 5. Clone the Repository

```bash
git clone git@github.com:jazersalazar/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 6. Configure Docker Desktop

Install Docker Desktop on Windows. In Docker Desktop, enable Ubuntu under:

```text
Settings → Resources → WSL Integration
```

Start Docker Desktop, then verify it inside Ubuntu:

```bash
docker --version
docker info
```

## 7. Run the Bootstrap

From the repository:

```bash
cd ~/dotfiles
./install.sh
```

The script installs the development tools and runs `link-dotfiles.sh`, which creates the dotfile symlinks. Existing files or incorrect symlinks are backed up with a timestamp before replacement. It also installs Tmux Plugin Manager and fetches the plugins declared in `tmux/tmux.conf`.

The base development tools are always installed. Codex CLI and Claude Code are optional: when run in a terminal, the installer asks about each one, and pressing Enter accepts the default of installing it. Flags can select them explicitly for unattended or repeatable setup:

```bash
./install.sh --with-codex --with-claude
./install.sh --without-codex
./install.sh --without-claude
./install.sh --without-codex --without-claude
```

When no terminal input is available, all optional components are installed by default unless a `--without-*` flag is supplied.

To install only the base environment without either AI coding tool:

```bash
./install.sh --without-codex --without-claude --without-go --without-rust --without-java
```

To install only selected optional components, combine the relevant flags. For example:

```bash
./install.sh --with-codex --with-claude --with-rust --without-go --without-java
```

When setup finishes, close Ubuntu completely and open a new terminal so the shell configuration and updated paths are loaded.

Authenticate the GitHub CLI after reopening the terminal:

```bash
gh auth login
```

Launch Codex from a project directory and sign in with ChatGPT when prompted:

```bash
cd ~/projects/YOUR_PROJECT
codex
```

Supabase CLI is intentionally installed per project so its version is pinned with the application. From a Supabase project:

```bash
pnpm add --save-dev supabase
pnpm supabase --version
```

## 8. Verify the Setup

Check the main tools:

```bash
for cmd in git gh codex nvim tmux lazygit starship node pnpm tsx python3 uv go rustc cargo java psql pg_dump docker; do
    printf "%-12s " "$cmd"
    command -v "$cmd" || echo "NOT FOUND"
done
```

Check GitHub and Docker:

```bash
gh auth status
ssh -T git@github.com
docker info >/dev/null && echo "Docker daemon reachable"
```

Check the repository:

```bash
cd ~/dotfiles
git status
```

# Updating the Environment

Pull the latest changes and rerun the installer:

```bash
cd ~/dotfiles
git pull
./install.sh
```

The installer also upgrades Lazygit when a newer official release is available.

Restart the terminal afterward if shell configuration or paths changed.

# Commit Conventions

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[(scope)][!]: <description>
```

| Type | Use for |
|---|---|
| `feat` | A new capability |
| `fix` | A bug fix |
| `refactor` | Restructuring with no change in behaviour |
| `docs` | Documentation only |
| `chore` | Housekeeping, no source or test change |
| `build` | Build, packaging or dependencies |
| `style` | Formatting only |
| `perf` | A performance improvement |
| `test` | Tests only |
| `ci` | CI configuration |
| `revert` | Reverting an earlier commit |

An optional lowercase scope names the area, as in `fix(tmux): stop the ticker
stacking`. A `!` before the colon marks a breaking change.

Two things enforce and assist this:

- `.githooks/commit-msg` rejects a subject that does not match. `link-dotfiles.sh`
  points `core.hooksPath` at that directory, so it installs itself on every
  machine. Bypass a single commit with `git commit --no-verify`.
- `commitizen` builds the message interactively. Run `cz commit` in a shell, or
  press `C` in the lazygit files panel. Its type list is the same eleven, so the
  wizard cannot produce a message the hook rejects.

commitizen reads its configuration only from the current directory, so `.cz.toml`
lives at the repository root and is linked to `~/.config/commitizen/cz.toml` as
well. `bin/cz-with-config` passes that copy to `--config` when a repository has
no configuration of its own, and leaves a project that has one alone. Prefer
`cz commit` over `git cz`: git runs the `git-cz` executable that uv installs
alongside `cz` in preference to any alias, which skips that fallback.

# Configuration Mapping

`link-dotfiles.sh` creates these symlinks:

| Repository file | Installed location |
|---|---|
| `bash/bashrc` | `~/.bashrc` |
| `bash/bash_aliases` | `~/.bash_aliases` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `tmux/quote.sh` | `~/.tmux/quote.sh` |
| `tmux/quote-rotate.sh` | `~/.tmux/quote-rotate.sh` |
| `tmux/quotes.txt` | `~/.tmux/quotes.txt` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `nvim/` | `~/.config/nvim` |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` |

Because these are symlinks, editing an installed configuration also changes the corresponding file in `~/dotfiles`.

# Custom Cheat Sheet

Only shortcuts and aliases explicitly customized in this repository are listed here.

## tmux

The prefix is tmux's default, `Ctrl+b`. Press the prefix, release it, and then press the listed key.

| Shortcut | Action |
|---|---|
| `Ctrl+b`, then `\|` | Split side by side |
| `Ctrl+b`, then `-` | Split top and bottom |
| `Ctrl+b`, then `r` | Reload the tmux configuration |
| `Ctrl+b`, then `h` / `j` / `k` / `l` | Select the pane left / down / up / right |
| `Ctrl+b`, then `H` / `J` / `K` / `L` | Resize the pane left / down / up / right by five cells |

Create or attach to a persistent IDE layout for the current project directory:

```bash
tmux-ide
```

The layout uses a wide left column: Neovim occupies its upper 65%, with a shell and Lazygit below it. Codex and Claude Code are stacked in the narrower right column. Each project directory gets its own session, so running it again in the same project reattaches to that session rather than creating another one. Pass a directory to start there:

```bash
tmux-ide ~/projects/my-app
```

Start the AI layout matching the current workspace:

```bash
tmux-ide-ai
tmux-ide-ai ~/projects/my-app
```

Codex fills the left 70%. The right 30% has Claude Code above a shell, split 70/30 vertically. Like `tmux-ide`, it reattaches to a persistent session per project when launched outside tmux. Its sessions are separate from `tmux-ide`. Inside tmux, run it in a one-pane window (`Ctrl+b`, then `c`).

Close all other panes in the current window, keeping the pane where you run it (programs in the closed panes are terminated):

```bash
tmux-clear
```

Close the current tmux window with one command:

```bash
tmux-close
```

## Neovim and tmux Navigation

The `vim-tmux-navigator` configuration provides navigation across Neovim splits and tmux panes:

| Shortcut | Action |
|---|---|
| `Ctrl+h` | Navigate left |
| `Ctrl+j` | Navigate down |
| `Ctrl+k` | Navigate up |
| `Ctrl+l` | Navigate right |
| `Ctrl+\` | Navigate to the previously active split or pane |

## Shell Aliases

| Alias | Command |
|---|---|
| `ls` | `eza --icons=auto` |
| `ll` | `eza -lah --git --icons=auto` |
| `la` | `eza -a --icons=auto` |
| `lt` | `eza --tree --level=2 --icons=auto` |
| `l` | `eza --icons=auto` |
| `b` | `bat` |

# Repository Workflow

After changing a dotfile:

```bash
cd ~/dotfiles
git diff
git add .
git diff --cached
git diff --cached --check
git commit -m "Describe the change"
git push
```

# Secrets

Never commit passwords, API keys, access tokens, private SSH keys, `.env` files, or other credentials. Keep SSH private keys under `~/.ssh/` and exclude project secrets with the appropriate `.gitignore` rules.
