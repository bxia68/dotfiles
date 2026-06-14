#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
INSTALL_TOOLS=1
USE_ROOT=no
DRY_RUN=0

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: ./install-macos.sh [options]

Options:
  --no-tools        Link dotfiles only; do not install tools.
  --with-root       Allow Homebrew bootstrap if brew is missing.
  --no-root         Do not use sudo/root; use existing Homebrew only. Default.
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
    --no-tools)
      INSTALL_TOOLS=0
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
  local current
  local backup

  ensure_dir "$(dirname -- "$dest")"

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

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

load_brew() {
  if have brew; then
    return 0
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  load_brew
  if have brew; then
    log "ok: Homebrew already installed"
    return
  fi

  if [ "$USE_ROOT" = "no" ]; then
    log "skip: Homebrew is missing and root use is disabled"
    return
  fi

  if ! have curl; then
    log "skip: curl is required to install Homebrew"
    return
  fi

  log "install: Homebrew"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew
  fi
}

install_brew_packages() {
  local package
  local packages=(
    zsh
    git
    curl
    ca-certificates
    fzf
    ripgrep
    bat
    jq
    starship
  )

  load_brew
  if ! have brew; then
    log "skip: Homebrew packages require brew"
    return
  fi

  log "install: Homebrew packages"
  run brew update

  for package in "${packages[@]}"; do
    if [ "$DRY_RUN" -ne 1 ] && brew list --formula "$package" >/dev/null 2>&1; then
      log "ok: $package already installed"
    else
      run brew install "$package"
    fi
  done
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

install_fzf_user() {
  if have fzf; then
    log "ok: fzf already installed"
    return
  fi

  if ! have git; then
    log "skip: git is required to install fzf without Homebrew"
    return
  fi

  if ! have curl && ! have wget; then
    log "skip: curl or wget is required to install fzf without Homebrew"
    return
  fi

  clone_or_update https://github.com/junegunn/fzf.git "$HOME/.fzf"
  log "install: fzf -> $HOME/.fzf/bin"
  ensure_dir "$HOME/.local/bin"

  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: $HOME/.fzf/install --bin --key-bindings --completion --no-update-rc"
    log "dry-run: ln -sf $HOME/.fzf/bin/fzf $HOME/.local/bin/fzf"
    return
  fi

  if [ ! -x "$HOME/.fzf/install" ]; then
    log "skip: $HOME/.fzf/install is missing"
    return
  fi

  "$HOME/.fzf/install" --bin --key-bindings --completion --no-update-rc
  if [ -x "$HOME/.fzf/bin/fzf" ]; then
    ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
  else
    log "warn: fzf binary was not created at $HOME/.fzf/bin/fzf"
  fi
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
  log "install: Starship -> $HOME/.local/bin"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: curl -fsSL https://starship.rs/install.sh -o /tmp/starship-install.sh"
    log "dry-run: sh /tmp/starship-install.sh -b $HOME/.local/bin -y"
  else
    tmp="$(mktemp)"
    curl -fsSL https://starship.rs/install.sh -o "$tmp" || {
      rm -f "$tmp"
      return 1
    }
    sh "$tmp" -b "$HOME/.local/bin" -y || {
      rm -f "$tmp"
      return 1
    }
    rm -f "$tmp"
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh/.git" ]; then
    log "update: $HOME/.oh-my-zsh"
    run git -C "$HOME/.oh-my-zsh" pull --ff-only
    return
  fi

  if [ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    log "ok: Oh My Zsh already installed"
    return
  fi

  if [ -e "$HOME/.oh-my-zsh" ]; then
    log "skip: $HOME/.oh-my-zsh exists and is not a git checkout"
    return
  fi

  if ! have git; then
    log "skip: git is required to install Oh My Zsh"
    return
  fi

  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

install_zsh_plugins() {
  local plugin_home="$HOME/.oh-my-zsh/custom/plugins"

  if ! have git; then
    log "skip: git is required to install zsh plugins"
    return
  fi

  if [ "$DRY_RUN" -ne 1 ] && [ ! -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    log "skip: Oh My Zsh is not installed"
    return
  fi

  ensure_dir "$plugin_home"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_home/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_home/zsh-syntax-highlighting"
  clone_or_update https://github.com/zsh-users/zsh-history-substring-search.git "$plugin_home/zsh-history-substring-search"
  clone_or_update https://github.com/zsh-users/zsh-completions.git "$plugin_home/zsh-completions"
  clone_or_update https://github.com/Aloxaf/fzf-tab.git "$plugin_home/fzf-tab"
}

install_tools() {
  install_homebrew
  install_brew_packages
  install_fzf_user
  install_starship
  install_oh_my_zsh
  install_zsh_plugins
}

link_dotfiles() {
  ensure_dir "$HOME/.config/shell"
  ensure_dir "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  ensure_dir "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"

  link_file "$SCRIPT_DIR/home/.zshrc" "$HOME/.zshrc"
  link_file "$SCRIPT_DIR/home/.zprofile" "$HOME/.zprofile"
  link_file "$SCRIPT_DIR/config/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
}

if ! is_macos; then
  log "error: install-macos.sh only supports macOS"
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  log "error: do not run this script as root; --with-root only allows Homebrew bootstrap"
  exit 1
fi

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
