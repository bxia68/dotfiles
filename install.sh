#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
INSTALL_TOOLS=0
USE_ROOT=auto
DRY_RUN=0

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --install-tools   Install supported packages and user-space tools.
  --with-root       Use apt through sudo/root on Ubuntu when installing tools.
  --no-root         Do not use sudo/root; only install user-space tools.
  --dry-run         Print intended actions without changing files.
  -h, --help        Show this help.
EOF
}

have() {
  command -v "$1" >/dev/null 2>&1
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: $*"
  else
    "$@"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-tools)
      INSTALL_TOOLS=1
      ;;
    --with-root)
      USE_ROOT=yes
      ;;
    --no-root)
      USE_ROOT=no
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

ensure_dir() {
  run mkdir -p "$1"
}

link_file() {
  local src="$1"
  local dest="$2"
  local dest_dir
  local current
  local backup

  dest_dir="$(dirname -- "$dest")"
  ensure_dir "$dest_dir"

  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      log "ok: $dest already points to $src"
      return
    fi
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="${dest}.backup.${TIMESTAMP}"
    log "backup: $dest -> $backup"
    run mv "$dest" "$backup"
  fi

  log "link: $dest -> $src"
  run ln -s "$src" "$dest"
}

is_ubuntu_like() {
  [ -r /etc/os-release ] || return 1
  . /etc/os-release
  case "${ID:-} ${ID_LIKE:-}" in
    *ubuntu*|*debian*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_ubuntu_packages() {
  local sudo_cmd=()

  is_ubuntu_like || return 0

  if [ "$USE_ROOT" = "no" ]; then
    log "skip: root package install disabled"
    return 0
  fi

  if [ "$(id -u)" -ne 0 ]; then
    if ! have sudo; then
      if [ "$USE_ROOT" = "yes" ]; then
        log "warn: --with-root requested, but sudo is not available"
      else
        log "skip: sudo is not available"
      fi
      return 0
    fi
    sudo_cmd=(sudo)
  fi

  log "install: Ubuntu shell packages"
  run "${sudo_cmd[@]}" apt-get update
  run "${sudo_cmd[@]}" apt-get install -y \
    zsh \
    git \
    curl \
    ca-certificates \
    fzf \
    ripgrep \
    bat \
    jq \
    command-not-found \
    python3-pygments
}

install_macos_packages() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  have brew || {
    log "skip: Homebrew not found"
    return 0
  }

  log "install: macOS shell packages"
  run brew install \
    starship \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search \
    zsh-completions \
    fzf
}

clone_or_update() {
  local repo="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    log "update: $dest"
    run git -C "$dest" pull --ff-only
    return
  fi

  if [ -e "$dest" ]; then
    log "skip: $dest exists and is not a git checkout"
    return
  fi

  log "clone: $repo -> $dest"
  run git clone --depth=1 "$repo" "$dest"
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "ok: Oh My Zsh already installed"
    return
  fi

  if ! have git; then
    log "skip: git is required to install Oh My Zsh"
    return
  fi

  log "install: Oh My Zsh"
  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

install_zsh_plugins() {
  local plugin_home="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

  if ! have git; then
    log "skip: git is required to install zsh plugins"
    return
  fi

  ensure_dir "$plugin_home"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_home/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_home/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-history-substring-search.git "$plugin_home/zsh-history-substring-search"
  clone_or_update https://github.com/zsh-users/zsh-completions.git "$plugin_home/zsh-completions"
}

install_starship() {
  local tmp

  if have starship; then
    log "ok: Starship already installed"
    return
  fi

  if ! have curl; then
    log "skip: curl is required to install Starship"
    return
  fi

  ensure_dir "$HOME/.local/bin"
  tmp="$(mktemp)"
  log "install: Starship -> $HOME/.local/bin"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: curl -fsSL https://starship.rs/install.sh -o $tmp"
    log "dry-run: sh $tmp -b $HOME/.local/bin -y"
  else
    curl -fsSL https://starship.rs/install.sh -o "$tmp"
    sh "$tmp" -b "$HOME/.local/bin" -y
    rm -f "$tmp"
  fi
}

install_tools() {
  install_ubuntu_packages
  install_macos_packages
  install_starship
  install_oh_my_zsh
  install_zsh_plugins
}

link_dotfiles() {
  ensure_dir "$HOME/.config/shell"
  ensure_dir "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
  ensure_dir "$HOME/.local/bin"

  link_file "$SCRIPT_DIR/home/.zshrc" "$HOME/.zshrc"
  link_file "$SCRIPT_DIR/home/.zprofile" "$HOME/.zprofile"
  link_file "$SCRIPT_DIR/config/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
}

if [ "$INSTALL_TOOLS" -eq 1 ]; then
  install_tools
fi

link_dotfiles

if have zsh; then
  zsh_path="$(command -v zsh)"
  if [ "${SHELL:-}" != "$zsh_path" ]; then
    log "hint: set zsh as your login shell with: chsh -s $zsh_path"
  fi
else
  log "warn: zsh is not installed; install it before using ~/.zshrc"
fi
