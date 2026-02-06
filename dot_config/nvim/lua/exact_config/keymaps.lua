-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Simplify Lazy keybind
vim.keymap.set("n", "<leader>l", "<Nop>")
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })

vim.keymap.set("n", "<leader>bs", "<cmd>update<cr>", { desc = "Save buffer" })
vim.keymap.set("n", "<leader>bS", "<cmd>wa<cr>", { desc = "Save all buffers" })
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Write buffer" })

-- Copy file path variants
vim.keymap.set("n", "<leader>fy", function()
  local abs_path = vim.fn.expand("%:p")
  local path

  -- Try to get path relative to git root
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.fn.expand("%:p:h")) .. " rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and git_root then
    -- In a git repo, use path relative to git root
    path = vim.fn.fnamemodify(abs_path, ":s?" .. git_root .. "/??")
  else
    -- Not in a git repo, use path relative to cwd
    path = vim.fn.expand("%:.")
  end

  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Yank relative file path (git root)" })

vim.keymap.set("n", "<leader>fY", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Yank absolute file path" })
