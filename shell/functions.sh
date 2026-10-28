# --- Archives ---
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress='tar -xzf'

# --- Video ---
webm2mp4() {
  ffmpeg -i "$1" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "${1%.webm}.mp4"
}

# --- Count and compare files, skipping macOS, iCloud, OneDrive and editor clutter ---
_clean_find() {
  find "$@" -type f \
    ! -name '.DS_Store' ! -name '._*' ! -name '*.icloud' ! -name 'Icon?' \
    ! -name '.tmp*' ! -name '~*' ! -name '.~lock.*' \
    ! -path '*/.onedrive*' ! -path '*/.Trash*'
}

countfiles() {
  local dir
  for dir in "${@:-.}"; do
    if [ ! -d "$dir" ]; then
      echo "Error: '$dir' is not a directory"
      continue
    fi
    echo "Directory: $dir"
    echo "Total files:   $(find "$dir" -type f | wc -l | tr -d ' ')"
    echo "Clean files:   $(_clean_find "$dir" | wc -l | tr -d ' ')  (excluding .DS_Store, .icloud, Icon, OneDrive temp)"
    echo
  done
}

difffiles() {
  local sizes=0 dir1 dir2 d only1 only2
  if [ "$1" = "--sizes" ]; then
    sizes=1
    shift
  fi
  dir1=${1%/} dir2=${2%/}
  if [ -z "$dir1" ] || [ -z "$dir2" ]; then
    echo "Usage: difffiles [--sizes] /path/to/dir1 /path/to/dir2"
    return 1
  fi
  for d in "$dir1" "$dir2"; do
    [ -d "$d" ] || { echo "Error: '$d' is not a directory"; return 1; }
  done

  _difffiles_list() {
    (
      cd "$1" || exit
      if [ "$sizes" = 0 ]; then
        _clean_find .
      elif stat --version >/dev/null 2>&1; then
        _clean_find . -exec stat -c '%s %n' {} +
      else
        _clean_find . -exec stat -f '%z %N' {} +
      fi
    ) | sed 's|\./||' | LC_ALL=C sort
  }
  only1=$(LC_ALL=C comm -23 <(_difffiles_list "$dir1") <(_difffiles_list "$dir2"))
  only2=$(LC_ALL=C comm -13 <(_difffiles_list "$dir1") <(_difffiles_list "$dir2"))

  echo "=== Only in dir1 ($(printf '%s' "$only1" | grep -c .) files) ==="
  echo "$dir1"
  echo "${only1:-(none)}"
  echo
  echo "=== Only in dir2 ($(printf '%s' "$only2" | grep -c .) files) ==="
  echo "$dir2"
  echo "${only2:-(none)}"
}
