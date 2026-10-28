# --- GNU tools and btop (CLI tools otherwise come from mise) ---
brew "coreutils"
brew "gnu-sed"
brew "grep"
brew "btop"

# --- Desktop apps and fonts (--full), skipped when already installed ---
if ENV["DOTFILES_PROFILE"] == "full"
  cask "ghostty" unless File.exist?("/Applications/Ghostty.app")
  cask "font-jetbrains-mono-nerd-font" if Dir[File.expand_path("~/Library/Fonts/JetBrainsMonoNerdFont-*")].empty?
  cask "visual-studio-code" unless File.exist?("/Applications/Visual Studio Code.app")
end
