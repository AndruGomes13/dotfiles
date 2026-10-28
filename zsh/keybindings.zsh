# --- Emacs keymap; word jumps stop at / and . ---
bindkey -e
WORDCHARS=${WORDCHARS//[\/.]}

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

# --- History: Up/Down match the typed prefix ---
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

# --- Word jumps ---
bindkey '^[[1;5D' backward-word # Ctrl+Left
bindkey '^[[1;5C' forward-word  # Ctrl+Right
bindkey '^[[1;3D' backward-word # Alt+Left
bindkey '^[[1;3C' forward-word  # Alt+Right

# --- Line start/end ---
bindkey '^[[H' beginning-of-line # Home
bindkey '^[OH' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F' end-of-line # End
bindkey '^[OF' end-of-line
bindkey '^[[4~' end-of-line

# --- Deleting and editing ---
bindkey '^[[3~' delete-char        # Delete
bindkey '^H' backward-kill-word    # Ctrl+Backspace (Ghostty sends ^W)
bindkey '^[[3;5~' kill-word        # Ctrl+Delete
bindkey '^[[3;3~' kill-word        # Alt+Delete
bindkey '^U' backward-kill-line    # Cmd+Backspace
bindkey '^[[Z' reverse-menu-complete # Shift+Tab
bindkey '^X^E' edit-command-line

# --- Shift-select by word with Ctrl (Linux) or Option (macOS), also over SSH ---
if (( $+widgets[shift-select::backward-word] )); then
  for _km in emacs shift-select; do
    bindkey -M $_km '^[[1;6D' shift-select::backward-word
    bindkey -M $_km '^[[1;6C' shift-select::forward-word
    bindkey -M $_km '^[[1;4D' shift-select::backward-word
    bindkey -M $_km '^[[1;4C' shift-select::forward-word
  done
  unset _km
fi
