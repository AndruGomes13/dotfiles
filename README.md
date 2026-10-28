# dotfiles

Terminal setup for macOS and Linux: zsh, Ghostty, tmux, Neovim (LazyVim), Starship and modern CLI tools, all in Gruvbox Dark.

```sh
curl -fsSL https://raw.githubusercontent.com/AndruGomes13/dotfiles/HEAD/install.sh | bash
```

The script clones this repo to `~/.local/share/dotfiles` (or pulls if it's already there), then links everything into place. Re-running it is safe: it skips what's installed, repairs broken links and never duplicates lines. Anything it replaces is moved to `~/.dotfiles-backup/<timestamp>/`.

## Profiles

```sh
curl -fsSL .../install.sh | bash -s -- --full      # desktop
curl -fsSL .../install.sh | bash -s -- --minimal   # headless server
```

| | `--minimal` | `--full` |
|---|---|---|
| zsh, CLI tools (mise), tmux, Neovim | ✓ | ✓ |
| Ghostty, JetBrains Mono Nerd Font, VS Code | | ✓ |

Without a flag, macOS and Linux desktops get `--full`; SSH sessions, containers and headless machines get `--minimal`. Add `--no-sudo` to never use sudo.

**Where things come from:**

- **CLI tools**: [mise](https://mise.jdx.dev) installs them into `~/.local/share/mise` on both OSes, so no sudo is needed.
- **Linux base packages**: apt installs zsh, git, curl and build-essential, only when sudo is available. Without sudo, zsh is installed to `~/.local` instead, and if that fails, bash is configured as the fallback.
- **macOS**: Homebrew installs the [Brewfile](Brewfile): GNU coreutils/sed/grep (put first in `PATH`), btop, and the GUI apps and fonts.

## Layout

```
install.sh        bootstrap: clone/pull, then run install/main.sh
install/          install steps (packages, tools, shell, links, extras)
zsh/ bash/ shell/ shell config; shell/ is shared by both
ghostty/ tmux/ nvim/ git/ starship/ bat/ btop/ lazygit/ atuin/
mise/tools.toml   CLI tool list
Brewfile          macOS packages
tests/            Docker test
```

In your home directory, `~/.zshrc` and `~/.bashrc` are two-line stubs that source the repo. Everything else is a symlink into it, so edit here and `git pull` updates every machine.

## Machine-specific settings (untracked)

| File | For |
|---|---|
| `~/.zshrc.local`, `~/.bashrc.local` | secrets, PATH additions, per-machine aliases |
| `~/.gitconfig` | `user.name`, `user.email`, overrides of [git/config](git/config) |
| `~/.config/nvim/lua/local.lua` | Neovim options and keymaps |
| `~/.config/ghostty/local.ghostty` | Ghostty overrides (e.g. `font-size`) |

## Adding a tool

- **CLI tool**: add it to [mise/tools.toml](mise/tools.toml) (`mise registry <name>` finds it), then rerun the installer or `mise install`.
- **macOS app or font**: add a `brew`/`cask` line to the [Brewfile](Brewfile). Put GUI-only entries inside the `full` block.
- **Config file**: put it in a new folder (e.g. `yazi/`) and add a `link yazi/yazi.toml "$HOME/.config/yazi/yazi.toml"` line to [install/links.sh](install/links.sh).
- **Shell setup**: guard it in [zsh/zshrc](zsh/zshrc) with `command -v tool >/dev/null && ...` so machines without the tool still work.

## Keys

| | |
|---|---|
| tmux prefix | `Ctrl-a` or `Ctrl-Space` |
| splits | `prefix \|` / `prefix -` (open in the current directory) |
| move between tmux panes and nvim splits | `Ctrl-h/j/k/l` |
| resize pane | `prefix H/J/K/L` |
| install / update tmux plugins | `prefix I` / `prefix U` |
| word jump | `Ctrl-←/→` (Linux), `Option-←/→` (macOS) |
| select text | `Shift` + any of the above, or `Shift-←/→/Home/End` |
| line start/end | `Home/End`, `Cmd-←/→` |
| delete word / to line start | `Ctrl-Backspace` or `Option-Backspace` / `Cmd-Backspace` |
| history | `↑/↓` match the typed prefix, `Ctrl-r` searches with atuin |

## Testing

```sh
tests/linux.sh                          # fresh Ubuntu container, non-root, no sudo
PLATFORM=linux/amd64 tests/linux.sh     # same on x86_64
```

The test installs twice, checks that the second run changes nothing, then breaks things and checks that a rerun repairs them.
