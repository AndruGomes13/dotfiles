#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/AndruGomes13/dotfiles/HEAD/install.sh | bash -s -- [--full|--minimal]
set -euo pipefail

main() {
  local repo=${DOTFILES_REPO:-https://github.com/AndruGomes13/dotfiles.git}
  local dir=${DOTFILES_DIR:-$HOME/.local/share/dotfiles}
  export DOTFILES_TS=${DOTFILES_TS:-$(date +%Y%m%d-%H%M%S)}

  if [[ $(uname -s) == Darwin ]] && ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    echo "error: finish installing the Xcode Command Line Tools, then rerun this command" >&2
    exit 1
  fi
  if ! command -v git >/dev/null 2>&1; then
    if [[ $EUID -eq 0 ]] && command -v apt-get >/dev/null 2>&1; then
      apt-get update -qq && apt-get install -y -qq git ca-certificates >/dev/null
    elif command -v apt-get >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y -qq git ca-certificates >/dev/null
    else
      echo "error: git is required" >&2
      exit 1
    fi
  fi

  if [[ -d $dir/.git ]]; then
    echo "==> Updating $dir"
    git -C "$dir" pull --quiet --rebase --autostash || echo "warning: could not update $dir, using the current checkout" >&2
  else
    if [[ -e $dir ]]; then
      local rel=${dir#"$HOME"/} bak=$HOME/.dotfiles-backup/$DOTFILES_TS
      mkdir -p "$bak/$(dirname "$rel")"
      mv "$dir" "$bak/$rel"
      echo "    backed up $dir"
    fi
    echo "==> Cloning $repo"
    mkdir -p "$(dirname "$dir")"
    git clone --quiet "$repo" "$dir"
  fi

  exec bash "$dir/install/main.sh" "$@"
}

main "$@"
