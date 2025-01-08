return {
  "9seconds/repolink.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "RepoLink",
  },

  keys = {
    { "<leader>gy", "<cmd>RepoLink! .<cr>", desc = "Yank url", mode = "n" },
    { "<leader>gY", "<cmd>RepoLink!<cr>", desc = "Yank permalink", mode = "n" },
  },

  opts = {
    use_full_commit_hash = true,
    bang_register = "+",
    -- your configuration goes here.
    -- keep empty object if you are fine with defaults
  },
}
