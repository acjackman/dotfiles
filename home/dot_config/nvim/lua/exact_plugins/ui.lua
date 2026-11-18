return {
  {
    "snacks.nvim",
    -- stylua: ignore
    keys = {
      -- use <leader>n for notes
      { "<leader>n", false, mode = {"i", "n", "s"} },
      { "<leader>N", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    },
  },
}
