#!/bin/bash

assert_not_empty() {
  local readonly var_name="$1"
  value=$(eval echo \$$var_name)
  if [ -z "$value" ]; then
    echo "The variable $var_name is empty!"
    exit 1
  fi
}

is_linux() {
  uname | grep -i linux 2>&1 >/dev/null
}

is_macos() {
  uname | grep -i darwin 2>&1 >/dev/null
}

is_wsl() {
  grep -i microsoft /proc/version 2>&1 >/dev/null
}

is_amd_gpu() {
  lspci | grep -i vga | grep AMD 2>&1 >/dev/null
}

is_nvidia_gpu() {
  lspci | grep -i vga | grep NVIDIA 2>&1 >/dev/null
}

is_ubuntu() {
  grep -i ubuntu /etc/os-release 2>&1 >/dev/null
}

install_deps_and_easy_package() {
  if is_linux; then
    sudo apt update
    sudo apt install -y git curl stow zsh vim cargo libevent-dev ncurses-dev build-essential bison pkg-config python3 python3-pip unzip
    cargo install lsd
  fi
}

install_tmux() {
  if is_linux; then
    curl -LO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
    tar xzf tmux-3.4.tar.gz
    cd tmux-3.4
    ./configure && make
    sudo make install
    cd ..
    rm -rf tmux-3.4*
  fi
}

install_zsh() {
  if is_linux; then
    echo "y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/joshskidmore/zsh-fzf-history-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
    curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
  fi
}

install_neovim() {
  if is_linux; then
    curl -LO https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux64.tar.gz
    tar xzf nvim-linux64.tar.gz
    sudo cp nvim-linux64/bin/nvim /usr/bin
    sudo cp -r nvim-linux64/share/nvim /usr/share
    sudo cp -r nvim-linux64/lib/nvim /usr/lib
    rm -rf nvim-linux64 nvim-linux64.tar.gz
  fi
}

install_fzf() {
  if is_linux; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    echo "y y n" | ~/.fzf/install
  fi
}

install_docker() {
  if is_linux && is_ubuntu; then
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \n "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \n  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \n sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    if ! getent group docker >/dev/null; then
      sudo groupadd docker
    fi
    if ! groups $USER | grep -q "\bdocker\b"; then
      sudo usermod -aG docker $USER
      newgrp docker
    fi

    sudo curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  fi
}

link_dotfiles() {
  if is_linux; then
    stow --adopt */
    git reset --hard
  fi
}

install_ollama() {
  if is_linux && is_amd_gpu; then
    docker run -d --name ollama --pull always --restart always \
      -p 127.0.0.1:11434:11434 -v ollama:/root/.ollama --stop-signal SIGKILL \
      --device /dev/dri --device /dev/kfd \
      -e HSA_OVERRIDE_GFX_VERSION=9.0.0 -e HSA_ENABLE_SDMA=0 \
      docker.io/ollama/ollama:rocm
  else
    docker run -d --name ollama --pull always --restart always \
      -p 127.0.0.1:11434:11434 -v ollama:/root/.ollama --stop-signal SIGKILL \
      docker.io/ollama/ollama
  fi
}

run_ollama_model() {
  docker exec ollama ollama pull phi3
  docker exec ollama ollama pull gemma2:2b
}

install_shell_gpt() {
  if is_linux; then
    pip3 install shell-gpt litellm
    sudo mkdir -p /opt/shell_gpt
    sudo chown -R $(whoami):$(whoami) /opt/shell_gpt
  fi
}

main() {
  local cmd=""
  local install_optional="false"

  while [ "$#" -gt 0 ]; do
    case "$1" in
    install | -i)
      cmd="install"
      ;;
    --install-optional)
      install_optional="true"
      shift
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
    esac
    shift
  done

  assert_not_empty "cmd"

  echo "Running $cmd command..."

  echo "Installing dependencies and easy packages..."
  install_deps_and_easy_package

  echo "Installing tmux..."
  install_tmux

  echo "Installing zsh..."
  install_zsh

  echo "Installing neovim..."
  install_neovim

  echo "Installing fzf..."
  install_fzf

  echo "Installing docker..."
  install_docker

  if [ "$install_optional" = "true" ]; then
    echo "Installing optional packages..."
    if is_linux; then
      sudo apt install -y exa bat fd-find ripgrep

      echo "Installing ollama..."
      install_ollama

      echo "Running ollama model..."
      run_ollama_model

      echo "Installing shell-gpt..."
      install_shell_gpt
    fi
  fi

  echo "Linking dotfiles..."
  link_dotfiles

  echo "Done!"
}

main "$@"
