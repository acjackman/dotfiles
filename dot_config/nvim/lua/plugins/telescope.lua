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

  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>.", ":Telescope file_browser path=%:p:h select_buffer=true<CR>" },
    },
  },
}
