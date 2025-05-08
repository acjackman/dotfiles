return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "terraform", "hcl" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {},
      },
    },
  },
  -- ensure terraform tools are installed
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "tflint" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        hcl = { "packer_fmt" },
        terraform = { "tofu_fmt" },
        tf = { "tofu_fmt" },
        tofu = { "tofu_fmt" },
        ["terraform-vars"] = { "tofu_fmt" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    specs = {
      {
        "ANGkeith/telescope-terraform-doc.nvim",
        ft = { "terraform", "hcl" },
        config = function()
          LazyVim.on_load("telescope.nvim", function()
            require("telescope").load_extension("terraform_doc")
          end)
        end,
      },
      {
        "cappyzawa/telescope-terraform.nvim",
        ft = { "terraform", "hcl" },
        config = function()
          LazyVim.on_load("telescope.nvim", function()
            require("telescope").load_extension("terraform")
          end)
        end,
      },
    },
  },
}
