return {
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- local luasnip = require("luasnip")
      local cmp = require("cmp")

      -- opts.mapping = vim.tbl_extend("force", opts.mapping, {
      opts.mapping = {
        -- From TJ https://github.com/tjdevries/config_manager/blob/eb8c846bdd480e6ed8fb87574eac09d31d39befa/xdg_config/nvim/after/plugin/completion.lua#L38
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<c-y>"] = cmp.mapping(
          cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }),
          { "i", "c" }
        ),
        ["<M-y>"] = cmp.mapping(
          cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          }),
          { "i", "c" }
        ),
        -- ["<tab>"] = false,
        ["<tab>"] = cmp.config.disable,

        -- Cody completion
        ["<c-a>"] = cmp.mapping.complete({
          config = {
            sources = {
              { name = "cody" },
            },
          },
        }),
      }
    end,
  },
}
