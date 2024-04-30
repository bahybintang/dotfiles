# Plugins
plugins=(tmux git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search dirhistory kubectl)


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
source $ZSH/oh-my-zsh.sh

setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

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
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# p10k
source $ZSH/custom/themes/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ $(uname) == "Darwin" ]]; then
  # GCloud SDK
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
fi

# Custom aliases
if [ -f ~/.zsh_aliases ]; then
    . ~/.zsh_aliases
fi

# Custom secrets
if [ -f ~/.zsh_secrets ]; then
	. ~/.zsh_secrets
fi

# Custom functions
if [ -f ~/.zsh_custom_functions ]; then
	. ~/.zsh_custom_functions
fi

# Custom exports
if [ -f ~/.zsh_exports ]; then
    . ~/.zsh_exports
fi
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Custom completions
if [ -f ~/.zsh_completions ]; then
    . ~/.zsh_completions
fi

# Custom applications
if [ -f ~/.zsh_applications ]; then
    . ~/.zsh_applications
fi

mkdir -p $HOME/.terraform.d/plugin-cache

[[ -s "/home/bintangbahy/.gvm/scripts/gvm" ]] && source "/home/bintangbahy/.gvm/scripts/gvm"
