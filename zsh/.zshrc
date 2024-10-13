# Plugins
plugins=(tmux git kubectl aws fzf-tab zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search dirhistory)

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# [ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ] && . "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Custom keybindings
bindkey '^ ' autosuggest-accept
bindkey '^[^?' backward-kill-word

# Plugins Variables
export ZSH_TMUX_AUTOSTART=false
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]='none'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=5'

export ZSH=$HOME/.oh-my-zsh
. $ZSH/oh-my-zsh.sh

setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# zsh history append
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space

# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu no
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'

# fzf configs
# Check if in tmux
if [ -n "$TMUX" ]; then
  export FZF_DEFAULT_OPTS='--height 40% --tmux center,40% --layout reverse --border'
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
else
  export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border'
fi
zstyle ':fzf-tab:*' popup-min-size 60 12
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
export FZF_CTRL_R_OPTS="--reverse"

# p10k
# [ -r $ZSH/custom/themes/powerlevel10k/powerlevel10k.zsh-theme ] && . $ZSH/custom/themes/powerlevel10k/powerlevel10k.zsh-theme
# [ -r ~/.p10k.zsh ] && . ~/.p10k.zsh

# Custom aliases
[ -r ~/.zsh_aliases ] && . ~/.zsh_aliases

# Custom secrets
[ -r ~/.zsh_secrets ] && . ~/.zsh_secrets

# Custom functions
[ -r ~/.zsh_custom_functions ] && . ~/.zsh_custom_functions

# Custom exports
[ -r ~/.zsh_exports ] && . ~/.zsh_exports
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Custom completions
[ -r ~/.zsh_completions ] && . ~/.zsh_completions

# Custom applications
[ -r ~/.zsh_applications ] && . ~/.zsh_applications

# oh-my-posh
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/config.toml)"
