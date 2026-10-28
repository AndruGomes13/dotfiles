# Helpers shared by the install steps. Must stay compatible with macOS's bash 3.2.

DOTFILES_TS=${DOTFILES_TS:-$(date +%Y%m%d-%H%M%S)}
BACKUP_DIR=$HOME/.dotfiles-backup/$DOTFILES_TS
WARNINGS=()

# --- Logging ---
if [[ -t 1 ]]; then
  BOLD=$'\e[1m' BLUE=$'\e[34m' YELLOW=$'\e[33m' RED=$'\e[31m' RESET=$'\e[0m'
else
  BOLD="" BLUE="" YELLOW="" RED="" RESET=""
fi

log() { printf '%s==>%s %s%s%s\n' "$BLUE" "$RESET" "$BOLD" "$*" "$RESET"; }
info() { printf '    %s\n' "$*"; }
warn() {
  printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2
  WARNINGS+=("$*")
}
die() {
  printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2
  exit 1
}
has() { command -v "$1" >/dev/null 2>&1; }
has_tty() { { : </dev/tty; } 2>/dev/null; }

# --- Platform, profile and sudo detection ---
detect_platform() {
  case $(uname -s) in
    Darwin) OS=macos ;;
    Linux) OS=linux ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac
  case $(uname -m) in
    x86_64 | amd64) ARCH=x86_64 ;;
    arm64 | aarch64) ARCH=arm64 ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

detect_profile() {
  if [[ $OS == macos || (-n ${DISPLAY:-}${WAYLAND_DISPLAY:-} && -z ${SSH_CONNECTION:-}) ]]; then
    echo full
  else
    echo minimal
  fi
}

SUDO="" SUDO_OK=0
detect_sudo() {
  if [[ $OS != linux ]] || ((NO_SUDO)); then return 0; fi
  if [[ $EUID -eq 0 ]]; then
    SUDO_OK=1
  elif has sudo && sudo -n true 2>/dev/null; then
    SUDO_OK=1 SUDO=sudo
  elif has sudo && has_tty && id -nG | grep -qwE 'sudo|wheel|admin'; then
    info "sudo is used for system packages"
    if sudo -v </dev/tty; then SUDO_OK=1 SUDO=sudo; fi
  fi
}

# --- File helpers: backup, link, rc_file, seed, clone ---

# Move an existing path into $BACKUP_DIR, keeping its location relative to $HOME.
backup() {
  local rel=${1#"$HOME"/}
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$1" "$BACKUP_DIR/$rel"
  info "backed up ~/$rel"
}

# link <path in repo> <target>: symlink target -> repo, backing up whatever was there.
link() {
  local src=$DOTFILES/$1 dst=$2
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then return 0; fi
  if [[ -e $dst || -L $dst ]]; then backup "$dst"; fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  info "linked $dst"
}

# rc_file <target> <line>: make <line>, which loads the repo, the first line of a shell rc
# file. Lines the user or other tools add below it are left alone. A file without the
# line is backed up and rewritten: if it loaded the dotfiles from an old path, its other
# lines are kept; otherwise they are kept commented out, so an old setup can't clash.
rc_file() {
  local dst=$1 line=$2 tmp
  if [[ -f $dst ]] && grep -qxF "$line" "$dst"; then return 0; fi
  tmp=$(mktemp)
  {
    printf '%s\n%s\n' "$line" "# Machine-specific settings go below."
    if [[ -f $dst ]] && grep -qE 'dotfiles/(zsh/zshrc|bash/bashrc)' "$dst"; then
      grep -vE 'dotfiles/(zsh/zshrc|bash/bashrc)|^# (Managed by dotfiles|Machine-specific settings go below)' "$dst" || true
    elif [[ -s $dst ]]; then
      printf '\n# Your previous ~/%s, commented out. Uncomment the lines you still need.\n' "${dst#"$HOME"/}"
      sed 's/^/# /' "$dst"
    fi
  } >"$tmp"
  if [[ -e $dst || -L $dst ]]; then backup "$dst"; fi
  mv "$tmp" "$dst"
  info "wrote $dst"
}

# seed <path in repo> <target>: for config files an app rewrites itself. Copy the
# template if the target is missing, otherwise only enforce the template's keys.
seed() {
  local src=$DOTFILES/$1 dst=$2 tmp
  if [[ -L $dst ]]; then backup "$dst"; fi
  if [[ ! -f $dst ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    info "created $dst"
    return 0
  fi
  tmp=$(mktemp)
  awk -F' *= *' 'NR == FNR { want[$1] = $0; next }
    ($1 in want) { print want[$1]; delete want[$1]; next }
    { print }
    END { for (k in want) print want[k] }' "$src" "$dst" >"$tmp"
  if cmp -s "$tmp" "$dst"; then
    rm -f "$tmp"
  else
    mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$HOME"/}")"
    cp "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
    mv "$tmp" "$dst"
    info "updated $dst"
  fi
}

clone() {
  if [[ -d $2/.git ]]; then return 0; fi
  if [[ -e $2 ]]; then backup "$2"; fi
  git clone --quiet --depth 1 "$1" "$2" || warn "could not clone $1"
}
