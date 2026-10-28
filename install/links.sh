link_configs() {
  local f
  log "Linking configs"

  # --- Shell rc files: small stubs that source the repo ---
  stub "$HOME/.zshrc" <<EOF
# Managed by dotfiles. Machine-specific settings go in ~/.zshrc.local.
[[ -r "$DOTFILES/zsh/zshrc" ]] && source "$DOTFILES/zsh/zshrc"
EOF
  stub "$HOME/.bashrc" <<EOF
# Managed by dotfiles. Machine-specific settings go in ~/.bashrc.local.
[ -r "$DOTFILES/bash/bashrc" ] && . "$DOTFILES/bash/bashrc"
EOF

  # --- App configs: symlinks into the repo ---
  link tmux/tmux.conf "$HOME/.tmux.conf"
  link nvim "$HOME/.config/nvim"
  link git/config "$HOME/.config/git/config"
  link git/ignore "$HOME/.config/git/ignore"
  link starship/starship.toml "$HOME/.config/starship.toml"
  link bat/config "$HOME/.config/bat/config"
  link lazygit/config.yml "$HOME/.config/lazygit/config.yml"
  link btop/themes/gruvbox_dark_v2.theme "$HOME/.config/btop/themes/gruvbox_dark_v2.theme"
  seed btop/btop.conf "$HOME/.config/btop/btop.conf"

  # --- Ghostty (desktop only); older config files would override this one ---
  if [[ $PROFILE == full ]]; then
    link ghostty/config "$HOME/.config/ghostty/config.ghostty"
    for f in "$HOME/.config/ghostty/config" \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"; do
      if [[ -e $f || -L $f ]]; then backup "$f"; fi
    done
  fi

  check_gitconfig
}

# ~/.gitconfig stays untracked for identity and machine-specific settings. It must
# exist, or `git config --global` would write into the repo through the symlink.
check_gitconfig() {
  local key mine
  [[ -f $HOME/.gitconfig ]] || touch "$HOME/.gitconfig"
  for key in $(git config -f "$DOTFILES/git/config" --name-only --list); do
    mine=$(git config -f "$HOME/.gitconfig" --get "$key" 2>/dev/null) || continue
    if [[ $mine != "$(git config -f "$DOTFILES/git/config" --get "$key")" ]]; then
      warn "~/.gitconfig sets $key = $mine, which overrides the dotfiles value"
    fi
  done
  if ! git config --global user.email >/dev/null; then
    info "set your git identity: git config --global user.name 'Name'; git config --global user.email 'you@example.com'"
  fi
}
