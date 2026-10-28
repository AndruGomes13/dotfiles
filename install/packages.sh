# --- System packages: Homebrew + Brewfile on macOS, apt on Linux (only with sudo) ---
install_packages() {
  if [[ $OS == macos ]]; then install_homebrew; else install_apt; fi
}

install_homebrew() {
  local brew=/opt/homebrew/bin/brew script
  [[ $ARCH == arm64 ]] || brew=/usr/local/bin/brew
  if [[ ! -x $brew ]]; then
    log "Installing Homebrew"
    script=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) || die "could not download the Homebrew installer"
    if has_tty; then /bin/bash -c "$script" </dev/tty; else NONINTERACTIVE=1 /bin/bash -c "$script"; fi
  fi
  eval "$("$brew" shellenv)"

  export DOTFILES_PROFILE=$PROFILE HOMEBREW_NO_ENV_HINTS=1
  if brew bundle check --no-upgrade --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
    info "Brewfile packages already installed"
  else
    log "Installing Brewfile packages"
    brew bundle --no-upgrade --file="$DOTFILES/Brewfile" || warn "brew bundle failed; rerun to retry"
  fi
}

install_apt() {
  local pkgs=(zsh git curl ca-certificates build-essential) missing=() p
  [[ $PROFILE == minimal ]] || pkgs+=(fontconfig xz-utils)
  if ! has dpkg; then
    if ! has zsh || ! has cc; then warn "not Debian-based: install zsh and a C compiler with your package manager"; fi
    return 0
  fi
  for p in "${pkgs[@]}"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if ((${#missing[@]} == 0)); then
    info "apt packages already installed"
  elif ((SUDO_OK)); then
    log "Installing apt packages: ${missing[*]}"
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" >/dev/null
  else
    warn "no sudo, skipped apt packages: ${missing[*]}"
  fi
}
