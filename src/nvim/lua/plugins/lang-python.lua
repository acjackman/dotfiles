local lsp = vim.g.lazyvim_python_lsp or "ruff_lsp"

return {}

-- return {
--   {
--     "nvim-treesitter/nvim-treesitter",
--     opts = function(_, opts)
--       if type(opts.ensure_installed) == "table" then
--         vim.list_extend(opts.ensure_installed, { "ninja", "python", "rst", "toml" })
--       end
--     end,
--   },
--   {
--     "neovim/nvim-lspconfig",
--     opts = {
--       servers = {
--         pyright = {
--           enabled = true,
--         },
--         basedpyright = {
--           enabled = lsp == "basedpyright",
--         },
--         [lsp] = {
--           enabled = true,
--         },
--         ruff_lsp = {
--           keys = {
--             {
--               "<leader>co",
--               function()
--                 vim.lsp.buf.code_action({
--                   apply = true,
--                   context = {
--                     only = { "source.organizeImports" },
--                     diagnostics = {},
--                   },
--                 })
--               end,
--               desc = "Organize Imports",
--             },
--           },
--         },
--       },
--       setup = {
--         ruff_lsp = function()
--           LazyVim.lsp.on_attach(function(client, _)
--             if client.name == "ruff_lsp" then
--               -- Disable hover in favor of Pyright
--               client.server_capabilities.hoverProvider = false
--             end
--           end)
--         end,
--       },
--     },
--   },
--   {
--     "nvim-neotest/neotest",
--     optional = true,
--     dependencies = {
--       "nvim-neotest/neotest-python",
--     },
--     opts = {
--       adapters = {
--         ["neotest-python"] = {
--           -- Here you can specify the settings for the adapter, i.e.
--           -- TODO: Setup neotest
--           -- runner = "pytest",
--           -- python = ".venv/bin/python",
--         },
--       },
--     },
--   },
--   {
--     "mfussenegger/nvim-dap",
--     optional = true,
--     dependencies = {
--       "mfussenegger/nvim-dap-python",
--       -- stylua: ignore
--       keys = {
--         { "<leader>dPt", function() require('dap-python').test_method() end, desc = "Debug Method", ft = "python" },
--         { "<leader>dPc", function() require('dap-python').test_class() end, desc = "Debug Class", ft = "python" },
--       },
--       config = function()
--         -- TODO: Setup dap
--         local path = require("mason-registry").get_package("debugpy"):get_install_path()
--         require("dap-python").setup(path .. "/.venv/bin/python")
--       end,
--     },
--   },
--   {
--     "linux-cultist/venv-selector.nvim",
--     cmd = "VenvSelect",
--     opts = function(_, opts)
--       if LazyVim.has("nvim-dap-python") then
--         opts.dap_enabled = true
--       end
--       return vim.tbl_deep_extend("force", opts, {
--         name = {
--           "venv",
--           ".venv",
--           "env",
--           ".env",
--         },
--       })
--     end,
--     keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" } },
--   },
--   {
--     "hrsh7th/nvim-cmp",
--     opts = function(_, opts)
--       opts.auto_brackets = opts.auto_brackets or {}
--       table.insert(opts.auto_brackets, "python")
--     end,
--   },
-- }