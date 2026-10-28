# --- zsh (to ~/.local when there's no sudo), antidote, and the login shell ---
setup_shell() {
  local script
  if ! has zsh && [[ $OS == linux ]]; then
    log "Installing zsh to ~/.local"
    if script=$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install) &&
      sh -c "$script" - -d "$HOME/.local" -e no -q -a sha256; then
      hash -r
    else
      warn "could not install zsh; bash will be used"
    fi
  fi
  clone https://github.com/mattmc3/antidote "$HOME/.local/share/zsh/antidote"
  set_login_shell
}

set_login_shell() {
  local zsh current user=${USER:-$(id -un)}
  zsh=$(command -v zsh) || return 0
  [[ $OS == macos ]] && zsh=/bin/zsh
  if [[ $OS == macos ]]; then
    current=$(dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}')
  else
    current=$(getent passwd "$user" 2>/dev/null | cut -d: -f7)
  fi
  if [[ ${current##*/} == zsh ]]; then return 0; fi

  if [[ $OS == linux ]] && ((SUDO_OK)) && grep -qx "$zsh" /etc/shells 2>/dev/null; then
    $SUDO chsh -s "$zsh" "$user" && info "login shell set to $zsh" || warn "could not change the login shell"
  elif [[ $OS == macos ]] && has_tty; then
    chsh -s "$zsh" </dev/tty || warn "could not change the login shell"
  else
    info "login shell unchanged; ~/.bashrc starts zsh for interactive sessions"
  fi
}
