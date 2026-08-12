require "nvchad.mappings"

local map = vim.keymap.set

-- Copilot: Ctrl+L acepta la sugerencia inline (linea completa).
-- Se define AQUI (despues de nvchad.mappings) para que gane sobre el
-- <C-l> = <Right> que NvChad asigna en modo insert.
map("i", "<C-l>", "<Plug>(copilot-accept-line)", { desc = "copilot: aceptar sugerencia" })

-- add yours here

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
