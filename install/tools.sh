# --- CLI tools via mise, into the home directory (no sudo) ---
install_tools() {
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  if ! has mise; then
    log "Installing mise"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh >/dev/null || die "could not install mise"
  fi
  link mise/tools.toml "$HOME/.config/mise/conf.d/dotfiles.toml"
  log "Installing CLI tools with mise"
  mise install --yes || warn "some CLI tools failed to install; rerun to retry"
}
