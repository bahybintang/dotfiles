if [ "$(uname)" = "Linux" ]; then
  apt update
  apt install 
  apt install -y git curl stow zsh tmux vim cargo
  echo "y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/joshskidmore/zsh-fzf-history-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  echo "y y n" | ~/.fzf/install
  cargo install lsd
  stow --adopt alacritty
  stow --adopt tmux
  stow --adopt vim
  stow --adopt zsh
  stow --adopt config
  git reset --hard
fi
