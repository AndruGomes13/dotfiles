#!/usr/bin/env bash
set -euo pipefail

# --- Load the install steps ---
DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
for f in lib packages tools shell links extras; do
  source "$DOTFILES/install/$f.sh"
done

# --- Options ---
usage() {
  cat <<EOF
Usage: install.sh [--full | --minimal] [--no-sudo]

  --full      Desktop: shell, CLI tools, nvim, tmux, Ghostty, fonts and GUI apps
  --minimal   Headless: shell, CLI tools, nvim and tmux
  --no-sudo   Never use sudo

Without a profile, macOS and Linux desktops get --full and everything else --minimal.
EOF
}

PROFILE="" NO_SUDO=0
while (($#)); do
  case $1 in
    --full) PROFILE=full ;;
    --minimal) PROFILE=minimal ;;
    --no-sudo) NO_SUDO=1 ;;
    -h | --help) usage && exit 0 ;;
    *) usage >&2 && die "unknown option: $1" ;;
  esac
  shift
done

# --- Detect platform, profile and sudo ---
detect_platform
[[ -n $PROFILE ]] || PROFILE=$(detect_profile)
detect_sudo
log "dotfiles: $OS/$ARCH, $PROFILE profile, sudo $( ((SUDO_OK)) && echo available || echo unavailable)"

# --- Install ---
install_packages
install_tools
setup_shell
link_configs
install_extras

# --- Summary ---
echo
if [[ -d $BACKUP_DIR ]]; then log "Replaced files were backed up to $BACKUP_DIR"; fi
if ((${#WARNINGS[@]})); then
  log "Finished with warnings:"
  for w in "${WARNINGS[@]}"; do info "- $w"; done
else
  log "Done"
fi
info "Open a new terminal or run: exec zsh"
