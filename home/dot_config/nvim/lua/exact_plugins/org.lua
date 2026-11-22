-- org.nvim: installed here, set up per repo. A notes repo's .nvim.lua (exrc) loads it
-- with that repo's options, so nothing org-specific runs elsewhere.
return {
  {
    "xheisenbugx/org.nvim",
    lazy = true,
    config = function() end, -- setup() comes from the repo's .nvim.lua
  },
  -- completion in blink.cmp (LazyVim default)
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = { org = { inherit_defaults = true, "org" } },
        providers = { org = { name = "Org", module = "org.completion.blink" } },
      },
    },
  },
  -- clock in the statusline, once a repo has set org.nvim up
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function() return package.loaded.org and require("org").statusline() or "" end,
      })
    end,
  },
}
