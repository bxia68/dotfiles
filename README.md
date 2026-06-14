# Dotfiles

Lean Ubuntu zsh setup for local machines and remote hosts. It works with root access when available and has a no-root mode for hosts where `zsh`, `git`, and `curl` are already installed.

## Install

Link dotfiles only:

```sh
./install.sh
```

Install Ubuntu packages plus Starship, Oh My Zsh, and zsh plugins:

```sh
./install.sh --install-tools --with-root
```

No-root mode only installs user-space tools when `git` and `curl` are already available:

```sh
./install.sh --install-tools --no-root
```

Existing destination files are moved aside with a timestamped `.backup.*` suffix before symlinks are created.

No-root mode cannot install Ubuntu packages, so `zsh` must already be installed on that host.

## Local Overrides

Secrets and machine-local exports belong here:

```sh
~/.config/shell/env.local.zsh
```

Login-shell-only local setup belongs here:

```sh
~/.config/shell/profile.local.zsh
```

## Prompt

Starship shows a context badge at the start of the prompt:

- `LOCAL:<host>` for local shells
- `SSH:<host>` for remote shells

This is automatic. The Starship config checks `SSH_CONNECTION` and `SSH_TTY`; when either is set, it shows the remote badge.

To make the distinction more obvious, edit [config/starship.toml](config/starship.toml):

```toml
[palettes.catppuccin_mocha]
base = '#1e1e2e'
green = '#a6e3a1'
red = '#f38ba8'

[custom.local_context]
format = '[LOCAL:$output]($style) '
style = 'bold fg:base bg:green'

[custom.remote_context]
format = '[SSH:$output]($style) '
style = 'bold fg:base bg:red'
```

The easiest changes are the label text (`LOCAL` / `SSH`) and the badge colors. For example, use `format = '[REMOTE:$output]($style) '`, change `red`, or change `style` to another palette color such as `style = 'bold fg:base bg:mauve'`.

## Shell Plugins

Oh My Zsh is kept intentionally small:

- built-in plugins: `git`, `sudo`, `command-not-found`, `extract`, `colored-man-pages`
- TTY-only built-in plugin: `fzf` when `fzf` is installed
- external plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`, `zsh-completions`, `fzf-tab`

`fzf-tab` is the one extra plugin beyond your previous setup; it gives searchable tab-completion menus without changing normal shell behavior much.
