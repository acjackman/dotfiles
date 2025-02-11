return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			local icons = LazyVim.config.icons

			opts.sections["lualine_z"] = {}
			opts.sections["lualine_c"] = {
				-- LazyVim.lualine.root_dir(),
				{
					"diagnostics",
					symbols = {
						error = icons.diagnostics.Error,
						warn = icons.diagnostics.Warn,
						info = icons.diagnostics.Info,
						hint = icons.diagnostics.Hint,
					},
				},
				{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
				{ LazyVim.lualine.pretty_path({ relative = "root", length = 0 }) },
			}
		end,
	},
}
