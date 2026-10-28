# --- Archives ---
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress='tar -xzf'

# --- Video ---
webm2mp4() {
  ffmpeg -i "$1" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "${1%.webm}.mp4"
}

# --- PDF: shrink embedded images with Ghostscript, output to ~/Downloads ---
pdfcompress() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: pdfcompress <file.pdf> [dpi]"
    echo "  dpi: image resolution, higher = better quality/bigger (72 small, 150 default, 300 print)"
    echo "  Writes ~/Downloads/<name>-<dpi>dpi.pdf; text and vector figures are unaffected"
    return 0
  fi
  command -v gs >/dev/null || { echo "Requires ghostscript (brew install ghostscript / apt install ghostscript)"; return 1; }
  local in="$1" dpi="${2:-150}"
  [[ -f "$in" ]] || { echo "File not found: $in"; return 1; }
  [[ "$dpi" =~ ^[0-9]+$ ]] || { echo "dpi must be a number (e.g. 150)"; return 1; }
  mkdir -p "$HOME/Downloads"
  local out="$HOME/Downloads/$(basename "${in%.[pP][dD][fF]}")-${dpi}dpi.pdf"
  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer \
     -dDownsampleColorImages=true -dDownsampleGrayImages=true \
     -dColorImageResolution="$dpi" -dGrayImageResolution="$dpi" \
     -dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic \
     -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$out" "$in" \
  && du -h "$in" "$out"
}

# --- Slurm clusters: idle nodes per partition, live view of your jobs ---
slurm-idle() {
  command -v sinfo >/dev/null || { echo "Slurm isn't available here (sinfo not found)"; return 1; }
  printf "h100 idle: %d nodes\n" \
    "$(sinfo -p hpc-mid -t idle -h -o '%D' | awk '{s+=$1} END {print s+0}')"
  printf "rtx  idle: %d nodes\n" \
    "$(sinfo -p rtx-mid -t idle -h -o '%D' | awk '{s+=$1} END {print s+0}')"
  printf "cpu  idle: %d nodes\n" \
    "$(sinfo -p cpu-mid -t idle -h -o '%D' | awk '{s+=$1} END {print s+0}')"
}

slurm-jobs() {
  command -v squeue >/dev/null || { echo "Slurm isn't available here (squeue not found)"; return 1; }
  watch -n 1 squeue --user "$USER"
}
