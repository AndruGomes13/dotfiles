# --- Post-install: plugins, history import, warm caches, Linux fonts and apps ---
install_extras() {
  install_tmux_plugins
  install_nvim_plugins
  import_history
  warm_zsh
  if [[ $PROFILE == full && $OS == linux ]]; then
    install_linux_font
    install_linux_apps
  fi
}

install_tmux_plugins() {
  local tpm=$HOME/.tmux/plugins/tpm sock
  has tmux || return 0
  clone https://github.com/tmux-plugins/tpm "$tpm"
  [[ -x $tpm/bin/install_plugins ]] || return 0
  log "Installing tmux plugins"
  # A private server, so a running tmux session is never touched. Retry once quietly,
  # since a single failed download would otherwise leave a plugin missing.
  sock=$(mktemp -d)
  tpm_install() { env -u TMUX TMUX_TMPDIR="$sock" "$tpm/bin/install_plugins" >/dev/null; }
  tpm_install 2>/dev/null || tpm_install || warn "could not install tmux plugins; rerun to retry"
  env -u TMUX TMUX_TMPDIR="$sock" tmux kill-server >/dev/null 2>&1 || true
  rm -rf "$sock"
}

install_nvim_plugins() {
  has nvim || return 0
  log "Installing Neovim plugins"
  nvim --headless "+Lazy! install" +qa >/dev/null 2>&1 || warn "Neovim plugins failed to install; they retry on first launch"
}

# Import zsh history into atuin once, while atuin's history is still empty.
import_history() {
  if has atuin && [[ -s $HOME/.zsh_history && -z $(atuin history list --cmd-only 2>/dev/null | head -n 1) ]]; then
    atuin import zsh >/dev/null 2>&1 || true
  fi
}

# Regenerate the plugin bundle and completion cache so the first shell starts fast.
warm_zsh() {
  local out
  has zsh || return 0
  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/{plugins.zsh,zcompdump}
  log "Installing zsh plugins"
  out=$(zsh -ic 'exit 0' </dev/null 2>&1 | grep -v '^# antidote cloning') || true
  if [[ -n $out ]]; then warn "zsh startup printed: $out"; fi
}

install_linux_font() {
  local dir=$HOME/.local/share/fonts/JetBrainsMonoNerdFont
  if ls "$dir"/*.ttf >/dev/null 2>&1; then return 0; fi
  if ! has xz; then
    warn "xz is missing, skipped JetBrains Mono Nerd Font"
    return 0
  fi
  log "Installing JetBrains Mono Nerd Font"
  mkdir -p "$dir"
  if ! curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJ -C "$dir"; then
    warn "could not install JetBrains Mono Nerd Font"
    return 0
  fi
  if has fc-cache; then fc-cache -f "$dir" >/dev/null; fi
}

install_linux_apps() {
  local app
  for app in ghostty code; do
    if has "$app"; then continue; fi
    if ((SUDO_OK)) && has snap; then
      log "Installing $app"
      $SUDO snap install "$app" --classic >/dev/null || warn "could not install $app"
    else
      warn "skipped $app: installing it needs sudo and snap"
    fi
  done
}
