# Dotfiles

Portable shell setup for macOS and Ubuntu. The same branch is intended to work on local machines, remote Ubuntu hosts, and machines where `sudo` is not available.

## Install

Link dotfiles only:

```sh
./install.sh
```

Ubuntu with `sudo` available:

```sh
./install.sh --install-tools --with-root
```

Ubuntu without `sudo`:

```sh
./install.sh --install-tools --no-root
```

No-root mode installs user-space pieces such as Starship and zsh plugins when `git` and `curl` are already available. It cannot install the system `zsh` package without root, so `zsh` must already exist on that host.

Existing destination files are moved aside with a timestamped `.backup.*` suffix before symlinks are created.

## Local Secrets

Do not put API keys or machine-local exports in tracked files. Put them in:

```sh
~/.config/shell/env.local.zsh
```

Login-shell-only local setup can go in:

```sh
~/.config/shell/profile.local.zsh
```

The zsh config sources these files when they exist.

## Starship Context

The prompt starts with a context badge:

- `LOCAL:<host>` for local shells
- `SSH:<host>` for remote shells

The remote badge is styled differently from the local badge so SSH sessions are obvious at a glance. The config uses ASCII labels instead of font-specific icons so it works on bare Ubuntu terminals too.
