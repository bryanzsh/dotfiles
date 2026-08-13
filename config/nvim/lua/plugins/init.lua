return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- GitHub Copilot: autocompletado inline + chat de ayuda
  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      -- NvChad usa Tab para cmp; desactivamos el Tab de copilot.
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      -- El <C-l> acepta la sugerencia (definido en lua/mappings.lua).
    end,
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = { { "nvim-lua/plenary.nvim", branch = "master" } },
    keys = {
      { "<leader>cc", "<cmd>CopilotChat<CR>", desc = "CopilotChat", mode = { "n", "v" } },
    },
    opts = {},
  },

  -- Treesitter: parsers para resaltado de sintaxis bonito.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "luadoc", "printf", "vim", "vimdoc",
        "python", "bash", "c", "html", "css", "json", "yaml", "markdown", "javascript",
      },
    },
  },

  -- Colorizer: muestra los codigos hex/colores con su color real en el codigo.
  {
    "NvChad/nvim-colorizer.lua",
    lazy = false,
    config = function()
      -- En headless (instalacion de parsers, CI) no hay termguicolors.
      if not vim.o.termguicolors then
        vim.o.termguicolors = true
      end
      pcall(function()
        require("colorizer").setup {
          filetypes = { "*" },
          user_default_options = {
            RGB = true,
            RRGGBB = true,
            RRGGBBAA = true,
            rgba = true,
            hsl = true,
            css = true,
            names = false,
          },
        }
      end)
    end,
  },
}
