if not vim.g.vscode then
  return {}
end

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymapsDefaults",
  callback = function()
    -- VSCode-specific keymaps for search and navigation
    vim.keymap.set("n", "<leader><space>", "<cmd>Find<cr>")
    vim.keymap.set("n", "<leader>/", [[<cmd>lua require('vscode').action('workbench.action.findInFiles')<cr>]])
    vim.keymap.set("n", "<leader>ss", [[<cmd>lua require('vscode').action('workbench.action.gotoSymbol')<cr>]])

    -- Keep undo/redo lists in sync with VsCode
    vim.keymap.set("n", "u", "<Cmd>call VSCodeNotify('undo')<CR>")
    vim.keymap.set("n", "<C-r>", "<Cmd>call VSCodeNotify('redo')<CR>")

    -- Navigate VSCode tabs like lazyvim buffers
    vim.keymap.set("n", "<S-h>", "<Cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>")
    vim.keymap.set("n", "<S-l>", "<Cmd>call VSCodeNotify('workbench.action.nextEditor')<CR>")
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymaps",
  callback = function()
    -- see https://github.com/tom-pollak/lazygit-vscode
    vim.keymap.set("n", "<leader>gg", [[<cmd>lua require('vscode').action('lazygit-vscode.toggle')<cr>]])
    vim.keymap.set("n", "<leader>sc", [[<cmd>lua require('vscode').action('workbench.action.showCommands')<cr>]])
    vim.keymap.set(
      "n",
      "-",
      [[<cmd>lua require('vscode').action('workbench.files.action.showActiveFileInExplorer')<cr>]]
    )
  end,
})

return {}
