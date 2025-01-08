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
      { "<leader>nn", "<cmd>ObsidianNew<cr>", desc = "New note", mode = "n" },
      { "<leader>no", "<cmd>ObsidianSearch<cr>", desc = "Search notes", mode = "n" },
      { "<leader>ns", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick Switch", mode = "n" },
      { "<leader>nb", "<cmd>ObsidianBacklinks<cr>", desc = "Show location list of backlinks", mode = "n" },
      -- { "<leader>nt", "<cmd>ObsidianTemplate<cr>", desc = "Follow link under cursor", mode = "n" },
      { "<leader>ndt", "<cmd>ObsidianToday<cr>", desc = "Open todays note", mode = "n" },
      -- { "<leader>ndd", "<cmd>ObsidianToday<cr>", desc = "Open todays note", mode = "n" }, -- TODO: Setup a calendar picker
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
      note_frontmatter_func = function(note)
        -- Add the title of the note as an alias.
        if note.title then
          note:add_alias(note.title)
        end

        local out = { title = note.title, aliases = note.aliases, tags = note.tags }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
      -- see below for full list of options 👇
      attachments = {
        -- The default folder to place images in via `:ObsidianPasteImg`.
        img_folder = "z/media/", -- This is the default
        ---@param client obsidian.Client
        ---@param path obsidian.Path the absolute path to the image file
        ---@return string
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },
    },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
  },
}
