# Dotfiles

Lean zsh setup for Ubuntu, macOS, local machines, and remote hosts. Installers default to no-root user-space setup and can use apt or Homebrew bootstrap when explicitly allowed.

## Install

### Ubuntu

Install tools and link dotfiles:

```sh
./install.sh
```

Use apt through sudo/root when installing Ubuntu packages:

```sh
./install.sh --with-root
```

No-root mode is the default. This skips apt and installs only user-space tools:

```sh
./install.sh --no-root
```

Existing destination files are moved aside with a timestamped `.backup.*` suffix before symlinks are created.

The no-root path never runs sudo or apt. It uses `git` for Oh My Zsh, zsh plugins, and `fzf`; it uses `curl` for Starship and `curl` or `wget` for fzf's binary installer.

The tool install path includes `fzf`. With root, Ubuntu installs it through apt. Without root, the installer clones `fzf` to `~/.fzf` and links the binary into `~/.local/bin`.

No-root mode cannot install Ubuntu packages such as `zsh`, `ripgrep`, `bat`, or `jq`, so install those through apt when root/sudo is available.

For link-only setup, use:

```sh
./install.sh --no-tools
```

### macOS

Install tools and link dotfiles:

```sh
./install-macos.sh
```

Allow Homebrew bootstrap if `brew` is missing:

```sh
./install-macos.sh --with-root
```

No-root mode is the default. It uses existing Homebrew only. If `brew` is missing, it still installs the user-space fallback tools it can and links dotfiles:

```sh
./install-macos.sh --no-root
```

The no-root path never runs sudo. It uses `git` for Oh My Zsh, zsh plugins, and `fzf`; it uses `curl` for Starship and `curl` or `wget` for fzf's binary installer.

The tool install path includes `fzf`. With Homebrew, macOS installs it as a formula. Without Homebrew, the installer clones `fzf` to `~/.fzf` and links the binary into `~/.local/bin`.

Without Homebrew, no-root mode cannot install formula packages such as `zsh`, `ripgrep`, `bat`, or `jq`.

Do not run the macOS script with `sudo`. The `--with-root` flag only allows the Homebrew bootstrap script to ask for privileges if Homebrew is missing.

For link-only setup, use:

```sh
./install-macos.sh --no-tools
```

New macOS zsh shells load Homebrew automatically from `/opt/homebrew` or `/usr/local`, so Starship and other formula tools are available even when the terminal starts with a minimal `PATH`. If a new shell still shows the default `%` prompt, confirm the terminal profile is starting `/bin/zsh` and rerun `./install-macos.sh`.

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
- custom `<label>:<host>` badges from local config

This is automatic by default for local and SSH shells. The zsh config sets `DOTFILES_SHELL_CONTEXT` to `local` or `ssh`, and Starship uses that value.

The local badge is hidden on `Bills-Laptop` to keep the normal local prompt quiet.

For container or machine-specific badges, set a custom context in `~/.config/shell/env.local.zsh`:

```sh
export DOTFILES_CONTEXT_LABEL=CTR
export DOTFILES_CONTEXT_COLOR=peach
```

That shows `CTR:<host>`. Supported colors are `green`, `red`, `peach`, `blue`, `mauve`, and `yellow`.

If you prefer a separate small config file, create `~/.config/shell/context`:

```sh
DOTFILES_CONTEXT_LABEL=CTR
DOTFILES_CONTEXT_COLOR=peach
```

There is also a copyable example at [config/shell/context.container.example](config/shell/context.container.example).

Custom context env vars win first. If they are absent, zsh reads `~/.config/shell/context`; if that file is absent too, it falls back to automatic SSH/local detection.

To force one of the built-in contexts instead, set one of these in `~/.config/shell/env.local.zsh`:

```sh
export DOTFILES_SHELL_CONTEXT_OVERRIDE=local
export DOTFILES_SHELL_CONTEXT_OVERRIDE=ssh
```

For a direct `ssh cuda-container` style connection, remember that the SSH alias `cuda-container` is only known to your local SSH client. If it still shows `SSH:<host>`, use the custom context env vars or file above inside that container.

Default badge colors and the `❯` prompt arrow live in [config/starship.toml](config/starship.toml).

## Shell Plugins

Oh My Zsh is kept intentionally small:

- built-in plugins: `git`, `sudo`, `command-not-found`, `extract`, `colored-man-pages`
- TTY-only built-in plugin: `fzf` when `fzf` is installed
- external plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`, `zsh-completions`, `fzf-tab`

`fzf-tab` is the one extra plugin beyond your previous setup; it gives searchable tab-completion menus without changing normal shell behavior much.
