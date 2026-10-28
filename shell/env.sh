# Environment shared by zsh and bash. Expects $DOTFILES to be set.

# --- PATH: Homebrew, GNU tools ahead of macOS ones, ~/.local/bin, mise ---
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$1:$PATH" ;;
  esac
}

for prefix in /opt/homebrew /usr/local; do
  if [ -z "${HOMEBREW_PREFIX:-}" ] && [ -x "$prefix/bin/brew" ]; then
    export HOMEBREW_PREFIX="$prefix"
    path_prepend "$prefix/sbin"
    path_prepend "$prefix/bin"
  fi
done
unset prefix
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  for pkg in grep gnu-sed coreutils; do
    path_prepend "$HOMEBREW_PREFIX/opt/$pkg/libexec/gnubin"
  done
  unset pkg
fi
path_prepend "$HOME/.local/share/mise/shims"
path_prepend "$HOME/.local/bin"
export PATH

# --- Editor ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if command -v nvim >/dev/null 2>&1; then export EDITOR=nvim; else export EDITOR=vi; fi
export VISUAL="$EDITOR" SUDO_EDITOR="$EDITOR"

# --- Remote hosts usually lack Ghostty's terminfo ---
case "${TERM:-}" in
  xterm-ghostty) infocmp xterm-ghostty >/dev/null 2>&1 || export TERM=xterm-256color ;;
esac

# --- fzf: fd for file search, Catppuccin colors ---
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"
fi
export FZF_DEFAULT_OPTS="--height 40% --layout reverse --border \
--color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7 \
--color=pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4"
