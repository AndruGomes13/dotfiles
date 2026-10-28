#!/usr/bin/env bash
# Installs twice, verifies, breaks things, reinstalls and verifies the repair.
# Run through tests/linux.sh (container) or tests/macos.sh (throwaway HOME).
set -uo pipefail
# What a login shell gets from ~/.profile and shell/env.sh
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
src=${SRC:-/src}
os=$(uname -s)
logs=$(mktemp -d)

failures=0
ok() { printf '  ok    %s\n' "$1"; }
bad() {
  printf '  FAIL  %s\n' "$1"
  failures=$((failures + 1))
}
check() {
  local name=$1
  shift
  if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi
}
expect_empty() {
  if [[ -z $2 ]]; then ok "$1"; else
    bad "$1"
    printf '%s\n' "$2" | sed 's/^/        /'
  fi
}
section() { printf '\n### %s\n' "$*"; }

# Stand-in for GitHub: a commit of the working tree, uncommitted changes included.
export DOTFILES_REPO=$HOME/origin
cp -R "$src" "$DOTFILES_REPO"
rm -rf "$DOTFILES_REPO/.git"
git -C "$DOTFILES_REPO" init -q
git -C "$DOTFILES_REPO" add -A
git -C "$DOTFILES_REPO" -c user.name=test -c user.email=test@example.com commit -qm test
dotfiles=$HOME/.local/share/dotfiles
printf ': 1700000000:0;echo imported-once\n' >>~/.zsh_history
echo 'export OLD_SETUP=1' >>~/.zshrc

for run in 1 2; do
  section "install, run $run (curl | bash)"
  start=$SECONDS
  bash <"$DOTFILES_REPO/install.sh" 2>&1 | tee "$logs/run$run.log"
  check "run $run exits 0" test "${PIPESTATUS[0]}" -eq 0
  echo "  ($((SECONDS - start))s)"
done

section "idempotency"
check "run 2 changed no files" bash -c "! grep -E '^    (backed up|linked|wrote|created|updated) ' $logs/run2.log"
check "run 2 has no zsh startup warnings" bash -c "! grep -q 'zsh startup printed' $logs/run2.log"
check "one backup dir (from run 1)" test "$(ls ~/.dotfiles-backup | wc -l)" -eq 1
check "existing .bashrc backed up" bash -c 'ls ~/.dotfiles-backup/*/.bashrc'
check ".zshrc sources the repo once" test "$(grep -c 'dotfiles/zsh/zshrc' ~/.zshrc)" -eq 1
check ".bashrc sources the repo once" test "$(grep -c 'dotfiles/bash/bashrc' ~/.bashrc)" -eq 1
check ".zshrc loads the repo on line 1" bash -c 'head -n 1 ~/.zshrc | grep -q dotfiles/zsh/zshrc'
check "old .zshrc kept below, commented out" grep -qx '# export OLD_SETUP=1' ~/.zshrc
check "old .zshrc lines don't run" zsh -ic '[[ -z $OLD_SETUP ]]'
check "zsh history imported into atuin once" test "$(zsh -ic 'atuin history list --cmd-only' 2>/dev/null | grep -c '^echo imported-once$')" -eq 1

section "platform"
if [[ $os == Linux ]]; then
  check "no sudo in the container" bash -c '! command -v sudo'
  check "zsh installed to ~/.local without sudo" test -x ~/.local/bin/zsh
  # Like Ghostty's SSH integration: a terminfo the system can read but the no-sudo zsh can't
  infocmp -x xterm-256color | sed 's/^xterm-256color|/xterm-ghostty|/' | tic -x -o ~/.terminfo - 2>/dev/null
  check "zsh falls back when it can't use xterm-ghostty" bash -c '[[ $(TERM=xterm-ghostty zsh -ic "print \$TERM" 2>/dev/null) == xterm-256color ]]'
else
  check "GNU sed/grep/ls come first" zsh -ic 'sed --version && grep --version && command ls --version'
  check "btop from Homebrew" zsh -ic 'command -v btop'
  ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
  if [[ -x $ghostty ]]; then
    expect_empty "Ghostty config is valid" "$("$ghostty" +validate-config --config-file="$HOME/.config/ghostty/config.ghostty" 2>&1)"
    check "Ghostty resolves the theme and font" bash -c "'$ghostty' +show-config | grep -q 'font-family = JetBrainsMono Nerd Font'"
  fi
  check "overriding Ghostty config moved aside" bash -c '! ls ~/Library/Application\ Support/com.mitchellh.ghostty/config* && ls ~/.dotfiles-backup/*/Library/Application\ Support/com.mitchellh.ghostty/config.ghostty'
fi

section "zsh"
expect_empty "interactive zsh starts without output" "$(zsh -ic 'exit 0' 2>&1 </dev/null)"
expect_empty "zsh inside the repo starts without output" "$(cd "$dotfiles" && zsh -ic 'exit 0' 2>&1 </dev/null)"
expect_empty "TERM=dumb starts without output" "$(TERM=dumb zsh -ic 'exit 0' 2>&1 </dev/null)"
bare=$(mktemp -d)
cp ~/.zshrc "$bare/"
expect_empty "starts cleanly without tools or plugins" \
  "$(env -i HOME="$bare" TERM=xterm PATH=/usr/bin:/bin "$(command -v zsh)" -ic 'exit 0' 2>&1 </dev/null)"
for t in mise fzf eza zoxide rg fd bat delta lazygit btop atuin jq tmux nvim starship gh tldr tree-sitter; do
  check "tool: $t" zsh -ic "command -v $t"
done
check "ls is eza" zsh -ic 'alias ls | grep -q eza'
check "cat is bat" zsh -ic 'alias cat | grep -q bat'
check "cd is zoxide" zsh -ic '[[ $(whence -w cd) == "cd: function" ]]'
check "functions loaded" zsh -ic 'whence -w difffiles countfiles compress n'
check "difffiles works" zsh -ic 'mkdir -p /tmp/df1 /tmp/df2 && touch /tmp/df1/a /tmp/df1/.DS_Store && difffiles /tmp/df1 /tmp/df2 | grep -qx a'
check "autosuggestions loaded" zsh -ic '(( $+functions[_zsh_autosuggest_start] ))'
check "shift-select loaded" zsh -ic '(( $+widgets[shift-select::backward-word] ))'
check "Ctrl+Left jumps words" zsh -ic '[[ $(bindkey "^[[1;5D") == *backward-word ]]'
check "Shift+Ctrl+Left selects words" zsh -ic '[[ $(bindkey "^[[1;6D") == *shift-select::backward-word ]]'
check "Shift+Option+Left selects words" zsh -ic '[[ $(bindkey "^[[1;4D") == *shift-select::backward-word ]]'
check "Up searches history prefix" zsh -ic '[[ $(bindkey "^[[A") == *up-line-or-beginning-search ]]'
check "Ctrl+R is atuin" zsh -ic '[[ $(bindkey "^R") == *atuin-search ]]'
check "case-insensitive completion" zsh -ic 'zstyle -L ":completion:*" matcher-list | grep -q "a-zA-Z"'
check "starship prompt" zsh -ic '[[ $PROMPT == *starship* ]]'
check "remote host shown only over SSH" bash -c 'h=$(hostname -s); SSH_CONNECTION="1 2 3 4" zsh -ic "starship prompt" 2>/dev/null | grep -q "$h" && ! zsh -ic "starship prompt" 2>/dev/null | grep -q "$h"'
check "history is large and shared" zsh -ic '(( SAVEHIST >= 100000 )) && [[ -o share_history ]]'
check "missing ghostty terminfo falls back" bash -c '[[ $(TERM=xterm-ghostty TERMINFO=/nonexistent zsh -ic "print \$TERM" 2>/dev/null) == xterm-256color ]]'
echo 'export LOCAL_OK=1' >>~/.zshrc
check "lines added below line 1 run" zsh -ic '[[ $LOCAL_OK == 1 ]]'
echo "  zsh startup: $(zsh -c 'zmodload zsh/datetime; s=$EPOCHREALTIME; zsh -ic "exit 0" </dev/null 2>/dev/null; printf %d $(( (EPOCHREALTIME - s) * 1000 ))')ms"

section "bash"
check "bash execs zsh at top level" bash -c '[[ $(echo "echo \$ZSH_VERSION" | SHLVL=0 bash -i 2>/dev/null) == [0-9]* ]]'
check "bash fallback works without zsh" bash -c 'DOTFILES_NO_ZSH=1 bash -ic "alias ls; type cd" 2>/dev/null | grep -q eza'

section "git"
if git config -f ~/.gitconfig core.pager >/dev/null; then
  check "~/.gitconfig overriding core.pager is reported" grep -q 'sets core.pager' "$logs/run1.log"
else
  check "delta is the pager" test "$(git config core.pager)" = delta
fi
check "delta renders a diff" bash -c "git -C $dotfiles show --color=always HEAD | delta --paging=never | grep -q zshrc"
check "~/.gitconfig exists (keeps writes out of the repo)" test -f ~/.gitconfig
check "TPM's blank GitHub login skips the credential helper" bash -c \
  '! printf "url=https://git:@github.com/x/y\npassword=\n\n" | GIT_TRACE=1 git credential approve 2>&1 | grep -q "credential-"'

section "tmux"
tmux -L t -f ~/.tmux.conf new -d -s t 2>/dev/null
sleep 2
check "prefix C-b" test "$(tmux -L t show -gv prefix)" = C-b
check "no second prefix" test "$(tmux -L t show -gv prefix2)" = None
check "status at the bottom" test "$(tmux -L t show -gv status-position)" = bottom
check "windows from 1" test "$(tmux -L t show -gv base-index)" = 1
check "panes from 1" test "$(tmux -L t show -gv pane-base-index)" = 1
check "escape-time 0" test "$(tmux -L t show -sv escape-time)" = 0
check "navigator C-h bound" bash -c 'tmux -L t list-keys -T root | grep -E "root +C-h .*select-pane -L"'
check "| splits in current dir" bash -c 'tmux -L t list-keys -T prefix | grep -E "prefix +\| .*pane_current_path"'
check "continuum hooked into status" bash -c 'tmux -L t show -gv status-right | grep -q continuum_save'
for p in tpm vim-tmux-navigator tmux-resurrect tmux-continuum; do
  check "plugin: $p" test -d ~/.tmux/plugins/$p
done
tmux -L t kill-server 2>/dev/null

section "neovim"
expect_empty "starts with gruvbox" \
  "$(nvim --headless "+lua if vim.g.colors_name ~= 'gruvbox' then io.write('wrong theme: ' .. tostring(vim.g.colors_name)) end" +qa 2>&1)"
check "plugins installed" test -d ~/.local/share/nvim/lazy/LazyVim
check "local.lua is sourced" bash -c 'echo "vim.g.local_ok = 1" >~/.config/nvim/lua/local.lua && [[ $(nvim --headless "+lua io.write(tostring(vim.g.local_ok))" +qa 2>&1) == 1 ]]; r=$?; rm ~/.config/nvim/lua/local.lua; exit $r'
if ! command -v cc >/dev/null; then
  expect_empty "opening a file without a C compiler shows no errors" "$(nvim --headless "$dotfiles/install/lib.sh" '+sleep 3' +qa 2>&1)"
fi

section "themes"
check "bat theme" bash -c 'grep -q "gruvbox-dark" "$(bat --config-file)"'
check "btop theme" grep -q gruvbox_dark_v2 ~/.config/btop/btop.conf
check "fzf colors" zsh -ic '[[ $FZF_DEFAULT_OPTS == *d65d0e* ]]'
check "atuin uses the repo config" bash -c "zsh -ic 'atuin info' 2>/dev/null | grep -q '$dotfiles/atuin/config.toml'"

section "repair"
rm ~/.config/starship.toml
ln -sfn /nonexistent ~/.tmux.conf
sed "s|$dotfiles/zsh/zshrc|/old/place/dotfiles/zsh/zshrc|g" ~/.zshrc >"$logs/zshrc" && cat "$logs/zshrc" >~/.zshrc
rm -rf ~/.local/share/zsh/plugins ~/.local/share/zsh/antidote ~/.tmux/plugins/tmux-resurrect ~/.local/share/mise/installs/fzf
bash "$dotfiles/install.sh" >"$logs/run3.log" 2>&1
check "run 3 exits 0" test $? -eq 0
check "starship.toml relinked" test "$(readlink ~/.config/starship.toml)" = "$dotfiles/starship/starship.toml"
check "broken .tmux.conf relinked" test "$(readlink ~/.tmux.conf)" = "$dotfiles/tmux/tmux.conf"
check "outdated .zshrc line repaired" bash -c "head -n 1 ~/.zshrc | grep -q '$dotfiles/zsh/zshrc' && ! grep -q /old/place ~/.zshrc"
check "your .zshrc lines kept through repair" grep -qx 'export LOCAL_OK=1' ~/.zshrc
check "broken .zshrc backed up" bash -c 'grep -q /old/place ~/.dotfiles-backup/*/.zshrc'
check "zsh plugins restored" zsh -ic '(( $+widgets[shift-select::backward-word] ))'
check "tmux plugin restored" test -d ~/.tmux/plugins/tmux-resurrect
check "fzf reinstalled" zsh -ic 'command -v fzf'

section "result"
if ((failures)); then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
