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
      -- Aceptar sugerencia inline con Ctrl+L (no choca con nada).
      vim.api.nvim_set_keymap("i", "<C-l>", "<Plug>(copilot-accept-line)", {})
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

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
