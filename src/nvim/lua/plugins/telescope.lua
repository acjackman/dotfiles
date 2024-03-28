return {
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
    keys = {
      -- Overload from LazyVim https://github.com/LazyVim/LazyVim/blob/cfbd3582736286433ee5532e1ea3a8d05a1e2649/lua/lazyvim/plugins/editor.lua#L181
      -- { "<leader>fF", LazyVim.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
    },
  },
}
