return {
  {
    "cappyzawa/trim.nvim",
    -- TODO: make this respect autoformat variable
    opts = {
      ft_blocklist = { "markdown" },
      -- if you want to remove multiple blank lines
      patterns = {
        [[%s/\(\n\n\)\n\+/\1/]], -- replace multiple blank lines with a single line
      },

      -- highlight trailing spaces
      highlight = false,
    },
  },
}
