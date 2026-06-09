# Login-shell setup. Keep machine-local additions in
# ~/.config/shell/profile.local.zsh.

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

[[ -r "$HOME/.config/shell/profile.local.zsh" ]] && source "$HOME/.config/shell/profile.local.zsh"
