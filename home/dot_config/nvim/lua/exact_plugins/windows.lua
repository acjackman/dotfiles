-- Move and resize across Neovim splits and the surrounding multiplexer with
-- one set of keys, via smart-splits.nvim and its per-multiplexer backends:
--   <C-h/j/k/l>    move; at a Neovim edge, cross into the multiplexer pane
--   <C-M-h/j/k/l>  resize (not <M-…>: AeroSpace owns alt+hjkl)
--
-- Each multiplexer needs its half too, so the keys reach Neovim when it is in
-- front: tmux via the smart-splits-nvim/backend-tmux TPM plugin
-- (dot_config/tmux/tmux.conf), Rex via ctrl(+alt)+hjkl bindings in
-- dot_config/rex/init.lua.
--
-- Not lazy loaded: the tmux backend marks the pane @pane-is-vim when the
-- plugin loads, and until then tmux swallows <C-h/j/k/l>.
return {
  {
    "smart-splits-nvim/smart-splits.nvim",
    version = "^3.0.0",
    lazy = false,
    dependencies = {
      -- tmux first: it is the inner multiplexer when tmux runs inside Rex.
      { "smart-splits-nvim/backend-tmux", main = "smart-splits-backend-tmux" },
      { "rawnly/smart-splits-backend-rex", opts = {} },
    },
    opts = {
      mux = { backend = { "smart-splits-backend-tmux", "smart-splits-backend-rex" } },
      move = {
        -- herdr has no maintained backend; while it's still around, hand off
        -- to it by hand. Everywhere else, wrap (tmux's and Rex's behaviour).
        at_edge = function(ctx)
          if not ctx.backend and vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
            local herdr = vim.env.HERDR_BIN_PATH
            if herdr == nil or herdr == "" then
              herdr = "herdr"
            end
            vim.fn.system({ herdr, "pane", "focus", "--direction", ctx.direction, "--current" })
          else
            ctx.wrap()
          end
        end,
      },
    },
    config = function(_, opts)
      local ss = require("smart-splits")
      ss.setup(opts)

      local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { silent = true, desc = desc })
      end
      map("<C-h>", ss.move_cursor_left, "Move left (split/pane)")
      map("<C-j>", ss.move_cursor_down, "Move down (split/pane)")
      map("<C-k>", ss.move_cursor_up, "Move up (split/pane)")
      map("<C-l>", ss.move_cursor_right, "Move right (split/pane)")
      map("<C-M-h>", ss.resize_left, "Resize left (split/pane)")
      map("<C-M-j>", ss.resize_down, "Resize down (split/pane)")
      map("<C-M-k>", ss.resize_up, "Resize up (split/pane)")
      map("<C-M-l>", ss.resize_right, "Resize right (split/pane)")
    end,
  },
}
