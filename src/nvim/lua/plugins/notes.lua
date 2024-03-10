return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = false,
    -- Load obsidian.nvim for all markdown files
    -- ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   "BufReadPre " .. vim.fn.expand("~") .. "/notes/**.md",
    --   "BufNewFile " .. vim.fn.expand("~") .. "/notes/**.md",
    -- },
    keys = {
      { "<leader>nn", "<cmd>ObsidianNew<cr>", desc = "New Obsidian note", mode = "n" },
      { "<leader>no", "<cmd>ObsidianSearch<cr>", desc = "Search Obsidian notes", mode = "n" },
      { "<leader>ns", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick Switch", mode = "n" },
      { "<leader>nb", "<cmd>ObsidianBacklinks<cr>", desc = "Show location list of backlinks", mode = "n" },
      { "<leader>nt", "<cmd>ObsidianTemplate<cr>", desc = "Follow link under cursor", mode = "n" },
    },
    opts = {
      workspaces = {
        {
          name = "Notes",
          path = "~/notes",
        },
      },
      note_path_func = function(spec)
        local path = spec.dir / "+" / tostring(spec.id)
        return path:with_suffix(".md")
      end,
      -- see below for full list of options 👇
    },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
  },
}
