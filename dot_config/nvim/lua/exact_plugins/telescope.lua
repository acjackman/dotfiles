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
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      {
        "<leader>fh",
        function()
          require("telescope.builtin")["find_files"]({ cwd = vim.fn.expand("%:p:h") })
        end,
        desc = "Find files (file)",
        mode = "n",
      },
    },
  },
}
