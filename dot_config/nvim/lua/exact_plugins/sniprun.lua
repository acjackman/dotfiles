return {
  {
    "michaelb/sniprun",
    branch = "master",

    build = "sh install.sh",
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

    config = function()
      require("sniprun").setup({
        display = { "Classic", "VirtualTextOk" },
        display_options = {
          notification_timeout = 5,
        },
        interpreter_options = {
          GFM_original = {
            use_on_filetypes = { "markdown", "markdown.pandoc" },
          },
        },
      })
    end,

    keys = {
      { "<leader>r", "", desc = "+run", mode = { "n", "v" } },
      { "<leader>rr", "<cmd>SnipRun<cr>", desc = "Run line", mode = "n" },
      { "<leader>rr", "<cmd>'<,'>SnipRun<cr>", desc = "Run selection", mode = "v" },
      { "<leader>rR", "<cmd>SnipRunOperator<cr>", desc = "Run (operator)", mode = "n" },
      { "<leader>rc", "<cmd>SnipClose<cr>", desc = "Close output" },
      { "<leader>rx", "<cmd>SnipReset<cr>", desc = "Reset" },
    },
  },
}
