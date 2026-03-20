#!/usr/bin/env bash
# Dotfiles installer — macOS & Linux
# Usage: ./install.sh [--optional] [--no-gui] [--dotfiles-only] [--help]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_VERSION="v0.10.1"

# ── Colors ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
  BLUE='\033[0;34m' BOLD='\033[1m' DIM='\033[2m' RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' DIM='' RESET=''
fi

# ── Logging ────────────────────────────────────────────────────────────────────
info()    { echo -e "  ${BLUE}→${RESET} $*"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET} $*"; }
error()   { echo -e "  ${RED}✗${RESET} $*" >&2; }
skip()    { echo -e "  ${DIM}↷ $* (already installed)${RESET}"; }
header()  { echo -e "\n${BOLD}══ $* ══${RESET}"; }

# ── Platform ───────────────────────────────────────────────────────────────────
is_macos()  { [[ "$OSTYPE" == darwin* ]]; }
is_linux()  { [[ "$OSTYPE" == linux* ]]; }
is_ubuntu() { [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release; }

# ── Helpers ────────────────────────────────────────────────────────────────────
installed() { command -v "$1" >/dev/null 2>&1; }

clone_if_missing() {
  local repo="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    skip "$(basename "$dest")"
  else
    info "Cloning $(basename "$dest")..."
    git clone --depth 1 "$repo" "$dest"
    success "$(basename "$dest")"
  fi
}

# ── Homebrew ───────────────────────────────────────────────────────────────────
setup_brew() {
  header "Homebrew"
  if installed brew; then
    skip "Homebrew"
    brew update --quiet
    return
  fi

  info "Installing Homebrew..."
  if is_linux && is_ubuntu; then
    sudo apt-get install -y build-essential procps curl file git
  fi
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for the rest of this script
  if is_macos; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  success "Homebrew"
}

pkg() {
  local name="$1"
  if brew list "$name" &>/dev/null; then
    skip "$name"
  else
    info "Installing $name..."
    brew install "$name" && success "$name"
  fi
}

cask() {
  is_macos || return 0
  local name="$1"
  if brew list --cask "$name" &>/dev/null; then
    skip "$name"
  else
    info "Installing $name..."
    brew install --cask "$name" && success "$name"
  fi
}

# ── Core ───────────────────────────────────────────────────────────────────────
install_core() {
  header "Core"
  for p in git stow curl wget gsed jq zsh vim; do pkg "$p"; done
}

# ── CLI Tools ──────────────────────────────────────────────────────────────────
install_cli_tools() {
  header "CLI Tools"
  for p in fzf eza bat ripgrep zoxide; do pkg "$p"; done
}

# ── Shell ──────────────────────────────────────────────────────────────────────
install_shell() {
  header "Shell"

  # oh-my-zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    skip "oh-my-zsh"
  else
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "oh-my-zsh"
  fi

  # plugins
  local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
  clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions"       "$dir/zsh-autosuggestions"
  clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting"   "$dir/zsh-syntax-highlighting"
  clone_if_missing "https://github.com/joshskidmore/zsh-fzf-history-search" "$dir/zsh-fzf-history-search"
  clone_if_missing "https://github.com/Aloxaf/fzf-tab"                      "$dir/fzf-tab"

  # oh-my-posh
  pkg oh-my-posh
}

# ── Tmux ───────────────────────────────────────────────────────────────────────
install_tmux() {
  header "Tmux"
  pkg tmux
  clone_if_missing "https://github.com/tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"
  warn "Run prefix+I inside tmux to install plugins"
}

# ── Neovim ─────────────────────────────────────────────────────────────────────
install_neovim() {
  header "Neovim"

  if installed nvim; then
    skip "neovim"
  elif is_macos; then
    pkg neovim
  else
    info "Installing neovim $NVIM_VERSION..."
    curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
    tar xzf nvim-linux64.tar.gz
    sudo cp nvim-linux64/bin/nvim /usr/bin
    sudo cp -r nvim-linux64/share/nvim /usr/share
    sudo cp -r nvim-linux64/lib/nvim /usr/lib
    rm -rf nvim-linux64 nvim-linux64.tar.gz
    success "neovim $NVIM_VERSION"
  fi
}

# ── Language Version Managers ──────────────────────────────────────────────────
install_lang_managers() {
  header "Language Version Managers"

  # Node — fnm (fast) + nvm (fallback, lazy loaded)
  pkg fnm
  if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | PROFILE=/dev/null bash
    success "nvm"
  else
    skip "nvm"
  fi

  # Python — pyenv
  pkg pyenv

  # Go — gvm (not in brew, script install)
  if [[ ! -d "$HOME/.gvm" ]]; then
    info "Installing gvm..."
    bash < <(curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    success "gvm"
  else
    skip "gvm"
  fi

  # Rust
  if installed rustup; then
    skip "rustup"
  else
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    success "Rust"
  fi

  # Deno
  pkg deno
}

# ── Cloud & Kubernetes ─────────────────────────────────────────────────────────
install_cloud() {
  header "Cloud & Kubernetes"

  # AWS
  pkg awscli
  if [[ ! -f /usr/local/bin/aws-sso ]]; then
    info "Installing aws-sso-cli..."
    local os arch
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
    local url
    url="$(curl -fsSL https://api.github.com/repos/synfinatic/aws-sso-cli/releases/latest \
      | grep "browser_download_url" | grep "${os}-${arch}" | grep -v sha256 | cut -d'"' -f4 | head -1)"
    if [[ -n "$url" ]]; then
      curl -fsSL "$url" -o /tmp/aws-sso && sudo mv /tmp/aws-sso /usr/local/bin/aws-sso && sudo chmod +x /usr/local/bin/aws-sso
      success "aws-sso-cli"
    else
      warn "Could not find aws-sso-cli binary, skipping"
    fi
  else
    skip "aws-sso-cli"
  fi

  # GCP
  pkg google-cloud-sdk
  if ! installed gke-gcloud-auth-plugin; then
    info "Installing gke-gcloud-auth-plugin..."
    gcloud components install gke-gcloud-auth-plugin --quiet
    success "gke-gcloud-auth-plugin"
  else
    skip "gke-gcloud-auth-plugin"
  fi

  # Kubernetes
  pkg kubectl
  brew tap fluxcd/tap 2>/dev/null || true
  pkg fluxcd/tap/flux

  # kubeswitch
  brew tap danielfoehrkn/switch 2>/dev/null || true
  pkg danielfoehrkn/switch/switcher

  # krew
  if [[ ! -d "${KREW_ROOT:-$HOME/.krew}" ]]; then
    info "Installing krew..."
    (
      set -euo pipefail
      local os arch tmpdir krew
      os="$(uname | tr '[:upper:]' '[:lower:]')"
      arch="$(uname -m | sed 's/x86_64/amd64/;s/arm.*$/arm/')"
      krew="krew-${os}_${arch}"
      tmpdir="$(mktemp -d)"
      cd "$tmpdir"
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew}.tar.gz"
      tar zxf "${krew}.tar.gz"
      ./"${krew}" install krew
      rm -rf "$tmpdir"
    )
    success "krew"
  else
    skip "krew"
  fi

  # Terraform / Terragrunt version managers
  if [[ ! -d "$HOME/.tfenv" ]]; then
    info "Installing tfenv..."
    git clone --depth 1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
    success "tfenv"
  else
    skip "tfenv"
  fi
  if [[ ! -d "$HOME/.tgenv" ]]; then
    info "Installing tgenv..."
    git clone --depth 1 https://github.com/tgenv/tgenv.git "$HOME/.tgenv"
    success "tgenv"
  else
    skip "tgenv"
  fi
}

# ── Containers ─────────────────────────────────────────────────────────────────
install_containers() {
  header "Containers"

  if is_macos; then
    if installed orbstack || installed docker; then
      skip "OrbStack / Docker"
    else
      cask orbstack
    fi
  fi

  if is_linux; then
    if installed docker; then
      skip "Docker"
    elif is_ubuntu; then
      info "Installing Docker..."
      sudo apt-get update -qq
      sudo apt-get install -y ca-certificates curl
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -qq
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      if ! getent group docker >/dev/null; then sudo groupadd docker; fi
      if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        warn "Log out and back in for Docker group to take effect"
      fi
      success "Docker"
    else
      warn "Non-Ubuntu Linux: install Docker manually for your distro"
    fi
  fi
}

# ── GUI Apps (macOS only) ──────────────────────────────────────────────────────
install_gui_apps() {
  is_macos || return 0
  header "GUI Apps (macOS)"
  cask ghostty
  cask alacritty
  cask raycast
  cask rectangle-pro
}

# ── Optional: AI Tools ─────────────────────────────────────────────────────────
install_optional() {
  header "Optional: AI Tools"

  # shell-gpt
  if installed sgpt; then
    skip "shell-gpt"
  else
    info "Installing shell-gpt..."
    pip3 install shell-gpt litellm
    sudo mkdir -p /opt/shell_gpt
    sudo chown -R "$(whoami)" /opt/shell_gpt
    success "shell-gpt"
  fi

  # ollama
  if installed ollama; then
    skip "ollama"
  elif is_macos; then
    cask ollama
  else
    info "Installing ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    success "ollama"
  fi
}

# ── Dotfiles ───────────────────────────────────────────────────────────────────
link_dotfiles() {
  header "Dotfiles"
  cd "$DOTFILES_DIR"
  info "Linking with stow..."
  stow --adopt --target="$HOME" */
  git reset --hard
  success "Dotfiles linked"
}

# ── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}Usage:${RESET} ./install.sh [options]

${BOLD}Options:${RESET}
  --optional       Also install optional packages (shell-gpt, ollama)
  --no-gui         Skip GUI app installation (useful for servers)
  --dotfiles-only  Only link dotfiles, skip all package installation
  -h, --help       Show this help

${BOLD}Examples:${RESET}
  ./install.sh                  # Full install
  ./install.sh --optional       # Full install + AI tools
  ./install.sh --no-gui         # Full install without GUI apps
  ./install.sh --dotfiles-only  # Just link dotfiles
EOF
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  local opt_optional=false opt_no_gui=false opt_dotfiles_only=false

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --optional)      opt_optional=true ;;
      --no-gui)        opt_no_gui=true ;;
      --dotfiles-only) opt_dotfiles_only=true ;;
      -h|--help)       usage; exit 0 ;;
      *) error "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done

  echo -e "${BOLD}Dotfiles Installer${RESET}"
  echo -e "  Platform : $(uname -s) (${OSTYPE})"
  echo -e "  Dotfiles : $DOTFILES_DIR"

  if ! $opt_dotfiles_only; then
    setup_brew
    install_core
    install_cli_tools
    install_shell
    install_tmux
    install_neovim
    install_lang_managers
    install_cloud
    install_containers
    $opt_no_gui  || install_gui_apps
    $opt_optional && install_optional
  fi

  link_dotfiles

  echo -e "\n${GREEN}${BOLD}Done!${RESET} Restart your terminal or run: ${BOLD}exec zsh${RESET}"
}

main "$@"
