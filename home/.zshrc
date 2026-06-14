# Interactive zsh config for Ubuntu and macOS. Keep secrets and machine-local
# exports in ~/.config/shell/env.local.zsh.

typeset -U path PATH fpath

[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" "${path[@]}")
[[ -d "$HOME/.fzf/bin" ]] && path=("$HOME/.fzf/bin" "${path[@]}")
[[ -d "$HOME/bin" ]] && path=("$HOME/bin" "${path[@]}")
[[ -d "$HOME/go/bin" ]] && path+=("$HOME/go/bin")
export PATH

[[ -r "$HOME/.config/shell/env.local.zsh" ]] && source "$HOME/.config/shell/env.local.zsh"

if [[ -z "${DOTFILES_CONTEXT_LABEL:-}" && -r "$HOME/.config/shell/context" ]]; then
  source "$HOME/.config/shell/context"
  [[ -n "${label:-}" && -z "${DOTFILES_CONTEXT_LABEL:-}" ]] && DOTFILES_CONTEXT_LABEL="$label"
  [[ -n "${color:-}" && -z "${DOTFILES_CONTEXT_COLOR:-}" ]] && DOTFILES_CONTEXT_COLOR="$color"
  unset label color
fi

_dotfiles_use_custom_context() {
  local color="${DOTFILES_CONTEXT_COLOR:-peach}"
  local label="${DOTFILES_CONTEXT_LABEL:-}"

  [[ -n "$label" ]] || return 1
  [[ "$label" =~ '^[A-Za-z0-9_.-]{1,16}$' ]] || label=CTX

  case "$color" in
    green|red|peach|blue|mauve|yellow) ;;
    *) color=peach ;;
  esac

  export DOTFILES_SHELL_CONTEXT=custom
  export DOTFILES_CONTEXT_LABEL="$label"
  export DOTFILES_CONTEXT_COLOR="$color"
}

_dotfiles_use_auto_context() {
  if [[ -n "${SSH_CONNECTION}${SSH_TTY}" ]]; then
    export DOTFILES_SHELL_CONTEXT=ssh
  else
    export DOTFILES_SHELL_CONTEXT=local
  fi
}

case "${DOTFILES_SHELL_CONTEXT_OVERRIDE:-}" in
  local|ssh)
    export DOTFILES_SHELL_CONTEXT="$DOTFILES_SHELL_CONTEXT_OVERRIDE"
    ;;
  *)
    if _dotfiles_use_custom_context; then
      :
    else
      _dotfiles_use_auto_context
    fi
    ;;
esac
unfunction _dotfiles_use_custom_context _dotfiles_use_auto_context

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

_fzf_has_builtin_zsh_integration() {
  local fzf_version
  fzf_version="${"$(fzf --version 2>/dev/null)"#fzf }"

  autoload -Uz is-at-least
  is-at-least 0.48.0 "${${(s: :)fzf_version}[1]}" 2>/dev/null
}

_fzf_has_key_bindings() {
  local fzf_base fzf_shell fzf_share

  [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && return 0
  [[ -n "${PREFIX:-}" && -r "$PREFIX/share/fzf/key-bindings.zsh" ]] && return 0

  for fzf_base in \
    "${FZF_BASE:-}" \
    "$HOME/.fzf" \
    "$HOME/.nix-profile/share/fzf" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/fzf" \
    "/usr/local/opt/fzf" \
    "/opt/homebrew/opt/fzf" \
    "/usr/share/fzf" \
    "/usr/local/share/examples/fzf"; do
    [[ -n "$fzf_base" && -d "$fzf_base" ]] || continue
    fzf_shell="$fzf_base"
    [[ -d "$fzf_base/shell" ]] && fzf_shell="$fzf_base/shell"
    [[ -r "$fzf_shell/key-bindings.zsh" ]] && return 0
  done

  if (( $+commands[fzf-share] )); then
    fzf_share="$(fzf-share 2>/dev/null)" || return 1
    [[ -r "$fzf_share/key-bindings.zsh" || -r "$fzf_share/shell/key-bindings.zsh" ]] && return 0
  fi

  return 1
}

_fzf_omz_plugin_safe() {
  [[ -t 0 && -t 1 ]] || return 1
  (( $+commands[fzf] )) || return 1

  _fzf_has_builtin_zsh_integration && return 0

  if (( $+commands[apt] || $+commands[apt-get] )); then
    if [[ -d /usr/share/doc/fzf/examples && ! -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
      return 1
    fi
    _fzf_has_key_bindings
    return
  fi

  return 0
}

if _fzf_omz_plugin_safe; then
  plugins+=(fzf)
fi
unfunction _fzf_has_builtin_zsh_integration _fzf_has_key_bindings _fzf_omz_plugin_safe

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
