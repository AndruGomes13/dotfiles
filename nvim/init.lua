-- --- LazyVim ---
require("config.lazy")

-- --- Machine-specific settings (untracked) ---
if vim.uv.fs_stat(vim.fn.stdpath("config") .. "/lua/local.lua") then
  require("local")
end
