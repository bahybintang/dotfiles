#!/bin/bash

install_deps_and_easy_package() {
  if [ "$(uname)" = "Linux" ]; then
    sudo apt update
    sudo apt install -y git curl stow zsh vim cargo libevent-dev ncurses-dev build-essential bison pkg-config
    cargo install lsd
  fi
}

install_tmux() {
  if [ "$(uname)" = "Linux" ]; then
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
  if [ "$(uname)" = "Linux" ]; then
    echo "y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/joshskidmore/zsh-fzf-history-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
  fi
}

install_neovim() {
  if [ "$(uname)" = "Linux" ]; then
    curl -LO https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz
    tar xzf nvim-linux64.tar.gz
    sudo cp nvim-linux64/bin/nvim /usr/local/bin
    rm -rf nvim-linux64 nvim-linux64.tar.gz
  fi
}

install_fzf() {
  if [ "$(uname)" = "Linux" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    echo "y y n" | ~/.fzf/install
  fi
}

link_dotfiles() {
  if [ "$(uname)" = "Linux" ]; then
    stow --adopt alacritty
    stow --adopt tmux
    stow --adopt vim
    stow --adopt zsh
    stow --adopt config
    git reset --hard
  fi
}

main() {
  install_deps_and_easy_package
  install_tmux
  install_zsh
  install_neovim
  install_fzf
  link_dotfiles
}

main "$@"
