# Ubuntu interactive zsh config. Keep secrets and machine-local exports in
# ~/.config/shell/env.local.zsh.

typeset -U path PATH fpath

[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" "${path[@]}")
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" "${path[@]}")
[[ -d "$HOME/go/bin" ]] && path+=("$HOME/go/bin")
export PATH

[[ -r "$HOME/.config/shell/env.local.zsh" ]] && source "$HOME/.config/shell/env.local.zsh"

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}" "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

setopt append_history
setopt auto_cd
setopt extended_glob
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify
setopt inc_append_history
setopt interactive_comments
setopt share_history

bindkey -e

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSH_THEME=""
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
zstyle ':omz:update' mode disabled

[[ -d "$ZSH_CUSTOM/plugins/zsh-completions/src" ]] && fpath=("$ZSH_CUSTOM/plugins/zsh-completions/src" "${fpath[@]}")

plugins=(
  git
  sudo
  command-not-found
  extract
  colored-man-pages
)

if [[ -t 0 && -t 1 ]] && (( $+commands[fzf] )); then
  plugins+=(fzf)
fi

[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && plugins+=(zsh-autosuggestions)
[[ -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]] && plugins+=(zsh-history-substring-search)
[[ -d "$ZSH_CUSTOM/plugins/fzf-tab" ]] && [[ -t 0 && -t 1 ]] && (( $+commands[fzf] )) && plugins+=(fzf-tab)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -d "$ZSH_COMPDUMP"

  _source_if_readable() {
    [[ -r "$1" ]] && source "$1"
  }

  _source_if_readable "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  _source_if_readable "$ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
  _source_if_readable "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

if (( $+functions[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# Syntax highlighting must load after Oh My Zsh plugins.
if [[ -r "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

alias gmo='git merge origin/'
alias la='ls -A'
alias ll='ls -lah'
if ! (( $+commands[bat] )) && (( $+commands[batcat] )); then
  alias bat='batcat'
fi

if [[ -t 1 ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi
