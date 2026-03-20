# Dotfiles

Personal dotfiles for macOS and Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

| Directory | Config for |
|---|---|
| `zsh` | Zsh, oh-my-zsh, plugins |
| `tmux` | Tmux + TPM plugins |
| `nvim` | Neovim (NvChad-based) |
| `vim` | Vim (fallback) |
| `git` | Git config, aliases, work profiles |
| `alacritty` | Alacritty terminal |
| `ghostty` | Ghostty terminal |
| `oh-my-posh` | Shell prompt theme |
| `shell_gpt` | shell-gpt config |
| `terraform` | Terraform plugin cache |
| `switch` | kubeswitch config |

## Quick start

Clone and run the installer:

```bash
git clone https://github.com/bahybintang/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer sets up all packages and links the dotfiles automatically. It's safe to re-run — every step checks if it's already installed.

## Installer options

```
./install.sh                  # Full install
./install.sh --optional       # Full install + AI tools (shell-gpt, ollama)
./install.sh --no-gui         # Skip GUI apps (useful for servers)
./install.sh --dotfiles-only  # Only link dotfiles, skip package installation
./install.sh --help           # Show all options
```

## Linking dotfiles manually

If you only want to link dotfiles without installing packages:

```bash
cd ~/.dotfiles
stow --adopt */
git reset --hard   # restore dotfiles content after --adopt
```

## Work configs

Work-specific git configs (email, SSH keys) live in `git/.config/git/work/` and are gitignored. Create them manually on each machine — see `git/.config/git/config` for the include structure.

## Adding a new app

1. Create a directory: `mkdir myapp`
2. Mirror the config path inside it, e.g. `myapp/.config/myapp/config`
3. Run `stow --adopt myapp` to link it
4. Run `git reset --hard` to restore the dotfiles content
