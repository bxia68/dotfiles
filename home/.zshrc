# Portable interactive zsh config. Keep secrets and machine-local exports in
# ~/.config/shell/env.local.zsh.

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""

for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

typeset -U path PATH fpath

_prepend_path() {
  [[ -d "$1" ]] && path=("$1" "${path[@]}")
}

_append_path() {
  [[ -d "$1" ]] && path+=("$1")
}

_source_if_readable() {
  [[ -r "$1" ]] && source "$1"
}

_source_first_readable() {
  local _candidate
  for _candidate in "$@"; do
    if [[ -r "$_candidate" ]]; then
      source "$_candidate"
      return 0
    fi
  done
  return 1
}

_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/.antigravity/antigravity/bin"
_append_path "$HOME/.spicetify"
_append_path "/usr/local/texlive/2023/bin/universal-darwin"
_append_path "/opt/homebrew/opt/postgresql@16/bin"

if (( $+commands[go] )); then
  _go_path="$(go env GOPATH 2>/dev/null)/bin"
  _append_path "$_go_path"
  unset _go_path
fi

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  export DOCKER_DEFAULT_PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/amd64}"
fi

_source_if_readable "$HOME/.config/shell/env.local.zsh"
_source_if_readable "$HOME/.local/bin/env"

_brew_prefix="${HOMEBREW_PREFIX:-}"
if [[ -z "$_brew_prefix" ]] && (( $+commands[brew] )); then
  _brew_prefix="$(brew --prefix 2>/dev/null)"
fi

_zsh_plugin_home="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

for _completion_dir in \
  "$_zsh_plugin_home/zsh-completions/src" \
  "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src" \
  "$_brew_prefix/share/zsh-completions"; do
  [[ -d "$_completion_dir" ]] && fpath=("$_completion_dir" "${fpath[@]}")
done
unset _completion_dir

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  plugins=(
    alias-finder
    aliases
    colorize
    command-not-found
    common-aliases
    copypath
    copyfile
    dotenv
    extract
    git
    jsontools
    sudo
    history
    colored-man-pages
  )

  [[ -d "$HOME/.ssh" ]] && plugins+=(ssh-agent)
  (( $+commands[docker] )) && plugins+=(docker docker-compose)
  (( $+commands[fzf] )) && plugins+=(fzf)
  (( $+commands[gh] )) && plugins+=(gh)

  if [[ "$OSTYPE" == darwin* ]] && (( $+commands[brew] )); then
    plugins+=(brew)
  fi

  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
fi

alias gmo='git merge origin/'
[[ -x /opt/homebrew/bin/g++-13 ]] && alias g++='/opt/homebrew/bin/g++-13'

# This keeps large pastes from being slowed down by autosuggest/url widgets.
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert "$OLD_SELF_INSERT"
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

_source_first_readable \
  "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$_zsh_plugin_home/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >/dev/null

_source_first_readable \
  "$_zsh_plugin_home/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$_brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh" >/dev/null

_source_first_readable \
  "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$_zsh_plugin_home/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >/dev/null

for _gcloud_dir in "$HOME/google-cloud-sdk" "$HOME/.local/google-cloud-sdk"; do
  _source_if_readable "$_gcloud_dir/path.zsh.inc"
  _source_if_readable "$_gcloud_dir/completion.zsh.inc"
done
unset _gcloud_dir

if [[ -t 1 ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

unset _brew_prefix _zsh_plugin_home
