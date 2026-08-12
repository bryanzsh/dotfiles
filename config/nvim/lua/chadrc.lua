-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "onedark",
	-- nvim hereda el fondo #000000 de kitty (negro 100%, consistente
	-- con el look de la VM). El tema solo aporta colores de sintaxis.
	transparency = true,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
    tabufline = {
        lazyload = false, -- pestañas con nombres SIEMPRE visibles (1+ buffer)
    },
}

return M
