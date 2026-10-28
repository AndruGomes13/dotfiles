# --- ls via eza ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons=auto --git'
  alias lta='lt -a'
fi

# --- cat via bat, fzf preview (Debian names them batcat and fdfind) ---
if command -v bat >/dev/null 2>&1; then
  _bat=bat
elif command -v batcat >/dev/null 2>&1; then
  _bat=batcat
  alias bat=batcat
fi
if [ -n "${_bat:-}" ]; then
  alias cat="$_bat --paging=never --style=plain"
  command -v fzf >/dev/null 2>&1 && alias ff="fzf --preview '$_bat --style=numbers --color=always {}'"
fi
unset _bat
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd=fdfind
fi

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Tools ---
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }
alias g='git'
alias d='docker'
alias lzg='lazygit'
alias lzd='lazydocker'

# --- Git ---
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
