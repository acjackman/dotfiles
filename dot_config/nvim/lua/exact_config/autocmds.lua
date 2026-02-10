-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--
vim.api.nvim_create_autocmd("InsertEnter", {
  pattern = "*.md",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*.md",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

-- Disable autoformat for lua files
-- vim.api.nvim_create_autocmd({ "FileType" }, {
--   -- pattern = { "lua" },
--   pattern = {},
--   callback = function()
--     vim.b.autoformat = false
--   end,
-- })
