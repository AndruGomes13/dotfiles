-- --- Skip compiling parsers where that can't work: no C compiler (e.g. servers without
-- sudo), or a tree-sitter CLI that can't run (its Linux builds need glibc 2.39+) ---
local function can_build_parsers()
  if vim.env.CC == nil and vim.fn.executable("cc") == 0 then
    return false
  end
  local ok, result = pcall(function()
    return vim.system({ "tree-sitter", "--version" }):wait()
  end)
  return ok and result.code == 0
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if not can_build_parsers() then
        opts.ensure_installed = {}
      end
    end,
  },
}
