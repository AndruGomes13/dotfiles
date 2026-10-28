-- --- Skip compiling parsers where there's no C compiler (e.g. servers without sudo) ---
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if vim.env.CC == nil and vim.fn.executable("cc") == 0 then
        opts.ensure_installed = {}
      end
    end,
  },
}
