# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/AndruGomes13/dotfiles/HEAD/install.sh | bash
```

Running it again updates and repairs the setup. Replaced files are backed up to `~/.dotfiles-backup/`.

## Options

Pass options after `bash -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/AndruGomes13/dotfiles/HEAD/install.sh | bash -s -- --minimal
```

| Option | Installs |
|---|---|
| `--full` | Shell, CLI tools, Neovim, tmux, Ghostty, fonts and GUI apps (desktop) |
| `--minimal` | Shell, CLI tools, Neovim and tmux (servers) |
| `--no-sudo` | Never use sudo; zsh and tools go in your home folder |

Without `--full` or `--minimal`, macOS and Linux desktops get `--full`, and SSH sessions and headless machines get `--minimal`.

## Update

```sh
dotfiles-update      # pull the latest changes and reload the shell
dotfiles-reinstall   # rerun the installer for new tools, links or apps (asks first)
```

`dotfiles-reinstall` takes the same options as the install command.

Without these functions (e.g. on a machine set up before they existed), pull manually, then open a new shell or run `exec zsh`:

```sh
git -C ~/.local/share/dotfiles pull
```
