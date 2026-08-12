# Shorcuts de nvim

> Guía de atajos y uso de **nvim + NvChad** (v2.5) de esta config.
> Líder: `Space`. Lista extraída de los **mappings reales** del sistema
> (también podés verla en vivo con `<Space>ch` → NvCheatsheet).

---

## 1. Cómo cambiar el tema

- **`Space + T h`** → abre el picker de temas de NvChad (telescope). Navegá, Enter, y queda guardado en `chadrc.lua`.
- Tema actual: `onedark` con `transparency = true` (el fondo es negro `#000000` de kitty; el tema solo aporta colores de sintaxis).
- Temas oscuros disponibles: `monochrome` (casi negro #101010), `carbonfox`, `oxocarbon`, `default-dark`, `catppuccin`, `tokyonight`, `nord`, `gruvbox`, `kanagawa`, etc. (ver con el picker).
- Config manual: `~/.config/nvim/lua/chadrc.lua` → `M.base46.theme = "nombre"`.

---

## 2. Movimiento y edición

### Modo insert (dentro de un texto)
| Atajo | Acción |
|---|---|
| `Ctrl+h j k l` | mover izquierda / abajo / arriba / derecha |
| `Ctrl+b` | ir al inicio de línea |
| `Ctrl+e` | ir al final de línea |

### Entre ventanas (splits)
| Atajo | Acción |
|---|---|
| `Ctrl+h` | ventana izquierda |
| `Ctrl+j` | ventana abajo |
| `Ctrl+k` | ventana arriba |
| `Ctrl+l` | ventana derecha |

### Saltos / rangos
| Atajo | Acción |
|---|---|
| `]d` / `[d` | siguiente / anterior diagnóstico |
| `]D` / `[D` | último / primer diagnóstico del buffer |
| `[` (espacio) | línea vacía arriba del cursor |
| `]` (espacio) | línea vacía abajo del cursor |
| `Ctrl+w d` / `Ctrl+w Ctrl+D` | diagnóstico bajo el cursor |

---

## 3. General

| Atajo | Acción |
|---|---|
| `Ctrl+s` | guardar archivo |
| `Ctrl+c` | copiar todo el archivo (`%y+`) |
| `Esc` | limpiar resaltados (noh) |
| `jk` | salir al modo normal (desde insert) |
| `;` | entrar a modo comando (dos puntos) |

---

## 4. Telescope (búsqueda — núcleo de NvChad)

| Atajo | Acción |
|---|---|
| `Space + ff` | buscar archivos |
| `Space + fa` | buscar todos archivos |
| `Space + fw` | **live grep** (buscar texto en el proyecto) |
| `Space + fb` | cambiar de buffer |
| `Space + fh` | ayuda (help tags) |
| `Space + fo` | archivos recientes (oldfiles) |
| `Space + fz` | buscar en el buffer actual (fuzzy) |
| `Space + ma` | marcas |
| `Space + cm` | git commits |
| `Space + gt` | git status |
| `Space + pt` | terminales ocultas |
| `Space + th` | **temas de NvChad** |

---

## 5. Buffers / pestañas (tabufline arriba)

> Con `M.ui.tabufline.lazyload = false` la barra con **nombres de archivo** se ve siempre.

| Atajo | Acción |
|---|---|
| `Tab` | buffer siguiente |
| `Shift+Tab` | buffer anterior |
| `Space + b` | buffer nuevo (`enew`) |
| `Space + x` | cerrar buffer actual |
| `Space + n` | toggle números de línea |
| `Space + rn` | toggle números relativos |

---

## 6. Nvimtree (explorador de archivos lateral)

| Atajo | Acción |
|---|---|
| `Ctrl+n` | abrir/cerrar el árbol |
| `Space + e` | enfocar el árbol |

---

## 7. Comentarios

| Atajo | Acción |
|---|---|
| `Space + /` | toggle comentario (normal) |
| `gcc` | comentar línea (normal) |
| `gc` | comentar selección (visual) |

---

## 8. LSP (asistencia de lenguaje)

| Atajo | Acción |
|---|---|
| `space + ds` | diagnosticos al loclist |
| `]d` / `[d` | siguiente / anterior diagnóstico |
| `Space + fm` | formatear archivo (conform) |

---

## 9. Terminal integrada

| Atajo | Acción |
|---|---|
| `Space + v` | terminal vertical |
| `Space + h` | terminal horizontal |
| `Alt+i` | terminal flotante (toggle) |
| `Alt+h` | terminal horizontal oculta (toggle) |
| `Alt+v` | terminal vertical oculta (toggle) |

---

## 10. Whichkey (guía visual de líder)

| Atajo | Acción |
|---|---|
| `Space + wk` | query lookup (qué atajo para qué) |
| `Space + wK` | todos los keymaps |
| `Space + ch` | **NvCheatsheet** (cheatsheet integrado con todo) |

---

## 11. Copilot (autocompletado inline + chat)

| Atajo | Acción |
|---|---|
| `Ctrl+l` | **aceptar la línea sugerida** (inline ghost text) |
| `Space + cc` | abrir CopilotChat (con selección visual adjunta) |
| `Alt+]` / `Alt+[` | ciclar sugerencias de copilot |
| `:Copilot` | estado / auth del plugin |

> Nota: `Tab` de copilot se desactivó porque NvChad usa `Tab` para el menú cmp. Para que responda hace falta hacer `:Copilot auth` una vez (red y root).

---

## 12. Cómo instalar plugins (lazy.nvim)

1. Abrí `~/.config/nvim/lua/plugins/init.lua` (checkout `config/nvim/lua/plugins/init.lua` del repo):
2. Dentro del `return { ... }` agregá una entrada con formato **`{ "usuario/repo", ... }`**:

```lua
return {
  -- ejemplo sencillo (carga lazily)
  { "github/copilot.vim", lazy = false, config = function() ... end },

  -- con dependencias y opts
  {
    "plugin-autor/repo",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = { { "<leader>cc", "<cmd>MiComando<CR>", mode = { "n", "v" } } },
  },
}
```

3. Guardar y correr `:Lazy` desde nvim:
   - `:Lazy sync` → instala/actualiza.
   - `:Lazy update` / `:Lazy clean` → actualizar / limpiar no usados.
4. Si el plugin necesita config custom, creá `lua/configs/<nombre>.lua` y referencialo con `opts = require "configs.<nombre>"`.
5. Los LSPs (lenguajes) se instalan aparte con **`:Mason`** (más abajo).

---

## 13. Cómo instalar LSPs / parsers (Mason + treesitter)

- **LSPs (autocompletado/errores por lenguaje):** en nvim → `:Mason` → buscá el lenguaje (ej. `lua-language-server`, `rust-analyzer`, `html`…) → Enter para instalar → recargar. Luego asegurate de que el servidor esté en `lua/configs/lspconfig.lua` (`servers = { ... }`).
- **Parsers de treesitter (resaltado de sintaxis nativo):** la mayoría ya vienen con NvChad; para más lenguajes edité `lua/plugins/init.lua` → nvim-treesitter `ensure_installed`.

---

## 14. Notas

- Líder = `Space`.
- Los atajos se extrajeron del sistema real; para confirmar/altera cualquier mapping, editá `lua/mappings.lua` (los del usuario) o `lua/plugins/init.lua` (los de plugins).
- Cheatsheet integrado en todo momento: `Space + ch`.