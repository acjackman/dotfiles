-- <C-h/j/k/l> navigation across Neovim splits and the surrounding multiplexer.
--
-- Moves between Neovim splits; at a split edge it hands off to herdr (when in a
-- herdr pane) or tmux (when $TMUX is set), so the same keys work in both. This
-- is the embedded Neovim side of vim-herdr-navigation
-- (paulbkim-dev/vim-herdr-navigation, editor/nvim.lua) folded into the
-- vim-tmux-navigator spec as the single source of truth for these mappings.
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- Let this spec own <C-h/j/k/l>; keep the :TmuxNavigate* commands for the
      -- tmux fallback below.
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      local function nav(wincmd, dir)
        local prev = vim.api.nvim_get_current_win()
        vim.cmd("wincmd " .. wincmd)
        if vim.api.nvim_get_current_win() ~= prev then
          return -- moved within Neovim
        end
        -- At a split edge: cross into the surrounding multiplexer.
        if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
          local herdr = vim.env.HERDR_BIN_PATH
          if herdr == nil or herdr == "" then
            herdr = "herdr"
          end
          vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
        elseif vim.env.TMUX and vim.env.TMUX ~= "" then
          local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
          pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
        end
      end

      local function map(lhs, wincmd, dir, desc)
        vim.keymap.set("n", lhs, function()
          nav(wincmd, dir)
        end, { silent = true, noremap = true, desc = desc })
      end

      map("<C-h>", "h", "left", "Navigate left (vim/herdr/tmux)")
      map("<C-j>", "j", "down", "Navigate down (vim/herdr/tmux)")
      map("<C-k>", "k", "up", "Navigate up (vim/herdr/tmux)")
      map("<C-l>", "l", "right", "Navigate right (vim/herdr/tmux)")

      -- tmux-only "last pane" toggle; harmless no-op outside tmux.
      vim.keymap.set("n", "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", {
        silent = true,
        noremap = true,
        desc = "Navigate to previous pane (tmux)",
      })
    end,
  },
}
