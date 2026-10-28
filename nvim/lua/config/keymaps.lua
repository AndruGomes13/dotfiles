-- --- Copy the current file's path ---
vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied path:\n" .. path)
end, { desc = "Yank file path" })

-- --- Cmd+C copies the selection (otherwise Neovim reads it as c and deletes it) ---
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to clipboard" })

-- --- Keep the cursor centered on half-page jumps ---
vim.keymap.set("n", "<C-d>", "<C-d>zz", { silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { silent = true })
