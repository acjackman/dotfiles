-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Simplify Lazy keybind
vim.keymap.set("n", "<leader>l", "<Nop>")
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })

vim.keymap.set("n", "<leader>bs", "<cmd>update<cr>", { desc = "Save buffer" })
vim.keymap.set("n", "<leader>bS", "<cmd>wa<cr>", { desc = "Save all buffers" })
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Write buffer" })
