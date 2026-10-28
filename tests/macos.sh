#!/usr/bin/env bash
# Install into a throwaway HOME on this Mac, twice, then verify. Your real HOME is not
# touched; Homebrew formulae from the Brewfile are installed for real (casks are skipped
# because their apps/fonts already exist in the sandbox or /Applications).
set -euo pipefail
src=$(cd "$(dirname "$0")/.." && pwd)
sandbox=$(mktemp -d)
ghostty_dir="$sandbox/Library/Application Support/com.mitchellh.ghostty"

mkdir -p "$sandbox/Library/Fonts" "$ghostty_dir"
touch "$sandbox/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
printf 'source ~/.local/share/omakub/defaults/zsh/rc-macos\n' >"$sandbox/.zshrc"
printf 'export OLD_BASHRC=1\n' >"$sandbox/.bashrc"
printf 'set -g mouse on\n' >"$sandbox/.tmux.conf"
printf 'font-family = "MesloLGS NF"\n' >"$ghostty_dir/config.ghostty"
printf '[core]\n\tpager = cat\n' >"$sandbox/.gitconfig"

echo "sandbox HOME: $sandbox"
env -i HOME="$sandbox" USER="$USER" TERM=xterm-256color PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  HOMEBREW_NO_AUTO_UPDATE=1 SRC="$src" ${GITHUB_TOKEN:+GITHUB_TOKEN="$GITHUB_TOKEN"} \
  bash "$src/tests/verify.sh"
