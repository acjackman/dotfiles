return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      mode = { "n" },
      { "<leader>n", group = "notes", icon = { icon = "⬣ ", color = "yellow" } },
      { "<leader>r", group = "run", icon = { icon = " ", color = "green" } },
    },
  },
}
