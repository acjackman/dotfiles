local lsp = vim.g.lazyvim_python_lsp or "ruff_lsp"

return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "ruff")
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["python"] = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      },
    },
  },
}
