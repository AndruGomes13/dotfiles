-- --- Over SSH, yanks go to the local clipboard through the terminal (OSC 52) ---
-- Pasting with p uses Neovim's own copy of the last yank, so it never waits on the
-- terminal; paste text copied elsewhere with Cmd+V.
if vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = { {}, "v" }
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste()
    return last
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
  vim.opt.clipboard = "unnamedplus"
end
