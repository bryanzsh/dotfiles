# actual.md — Cambios actuales del entorno y por qué están así

> Documento enfocado: **qué está configurado HOY** y **por qué** se eligió cada valor. Si necesitas la bitácora histórica completa, ver `entorno.md`.

---

## 1. Resumen del sistema

| | |
|---|---|
| Distro | Kali GNU/Linux Rolling 2026.3 (VM, GPU virtual VMware SVGA II) |
| WM | bspwm 0.9.12 · sxhkd 0.6.3 · polybar 3.7.2 · picom 13 · kitty 0.47.3 |
| Terminal/shell | kitty · zsh (red y root) |
| Teclado | latam |

**Por qué todo gira en esto:** la GPU es virtual → el OpenGL por software (llvmpipe) es caro. Por eso picom usa `xrender` y todo se mantiene ligero.

---

## 2. bspwm — `~/.config/bspwm/bspwmrc`

**Configurado así:**
- 9 escritorios `1..9`
- `border_width 1` · borde de la ventana enfocada **blanco** (`#ffffff`), resto gris `#30302f`
- `window_gap 8`
- Teclado latam · wallpaper feh · autostart con guardas `pgrep`/`pkill`
- Monitor de polybar detectado por `xrandr` (sin hardcodear)

**Por qué:**
- 9 escritorios → coinciden con `Super+[1-9]` y `Super+Shift+[1-9]`.
- Borde blanco de 1px → resalta la ventana enfocada (la que controla `Ctrl+flechas`) sin pesadez visual.
- `gap 8` → se bajó de 12 para un layout compacto que aproveche la pantalla.
- Guardas anti-duplicado → bspwmrc se re-ejecuta en `Super+Alt+r`; sin `pgrep` habría dobles procesos (doble RAM/CPU).
- Monitor dinámico → el nombre cambia entre tu VM, otras VMs y Xvfb; hardcodearlo rompe la barra.

---

## 3. Atajos — `~/.config/sxhkd/sxhkdrc`

| Atajo | Acción |
|---|---|
| `Super+Enter` | abre kitty |
| `Super+Q` | cierra ventana enfocada |
| `Super+Space` | toggle tiling/floating |
| `Super+1..9` | cambia de escritorio |
| `Super+Shift+1..9` | **mueve la ventana enfocada** al escritorio |
| `Ctrl+↑↓←→` | mueve el foco entre ventanas (bspwm) |
| `Super+Escape` | recarga sxhkd |
| `Super+Alt+Q` / `Super+Alt+R` | salir / reiniciar bspwm |

**Por qué:**
- `Super+Shift+[1-9]` usa `bspc node -d` (mueve el **nodo**), distinto de `bspc desktop -f` (solo cambia). → con 2 ventanas, enfocas una y la mandas al escritorio que elijas.
- `Ctrl+flechas` asumió el conflicto con el salto de palabra en terminales (readline) porque priorizas navegar ventanas sin mouse. Cambiar a `super` es 1 línea si molesta.

---

## 4. Polybar — `~/.config/polybar/config.ini`

**Configurado así:**
- Barra **negra** (`#000000`) con texto **blanco** (`#ffffff`)
- Workspace enfocado **invertido**: fondo blanco + letra negra
- Compacta: `height 20` · fuente `DejaVu Sans Mono:size=8` · paddings/márgenes mínimos
- Módulos: workspaces · CPU · RAM · **IP eth0** · fecha/hora
- Sin tray (desactivado a propósito)

**Por qué:**
- Negro/blanco + chip invertido → máximo contraste, el escritorio activo salta a la vista.
- Módulos todos `internal/*` (sin scripts) → consumo mínimo (~2% CPU, sin procesos hijos).
- La IP sale con `%local_ip%` (variable interna de polybar 3.7.2) → cero scripts externos.
- Compacta → ocupa menos y combina con el resto del look minimalista.

---

## 5. Picom — `~/.config/picom/picom.conf`

**Configurado así:**
- `backend = "xrender"` · `vsync = false`
- Esquinas redondeadas `corner-radius 12` (barra/docks/menús/fullscreen quedan rectos vía rules)
- Opacidad: enfocada `0.90` / inactiva `0.80`
- Blur `dual_kawase` con `blur-strength 5`
- Sombras suaves (`opacity 0.20`)
- Fading/animaciones OFF · `unredir-if-possible` ON
- Log en `/tmp/picom.log`

**Por qué (los 3 más importantes):**
- **`xrender`**: GPU virtual → `egl`/`glx` usaría llvmpipe (GL por software) y dispararía la CPU. `xrender` es el render 2D de X: barato y suficiente. **No cambiar a GL sin GPU real.**
- **`dual_kawase` 5**: el método de blur más eficiente (2 pasadas). El blur se ve **a través de las ventanas inactivas** semi-transparentes. Si la CPU pasara de ~6-7% al mover ventanas, bajar `blur-strength` a 3 o poner `"none"`.
- **Opacidad 0.90/0.80 + esquinas**: lo pediste (redondeado + blur + opacidad menor); la enfocada se mantiene legible y la inactiva deja ver el fondo desenfocado.

---

## 6. Kitty — `~/.config/kitty/kitty.conf`

**Configurado así:**
- Fuente: **JetBrainsMono Nerd Font** (variante no-Mono) · `font_size 10`
- Fondo **negro total `#000000`** (override al final, tras la theme Catppuccin Mocha)
- `background_opacity 0.80` (ajustable en vivo con `Ctrl+Shift+O`)
- Splits internos: `Ctrl+Shift+flechas` · nuevo split `Ctrl+Shift+Enter`
- Sin `adjust_line_height` (alto de línea por defecto)

**Por qué:**
- **No-Mono y no Hack**: la doc de NvChad recomienda la variedad **no-Mono** (iconos de lsd/NvChad ligeramente más grandes). Se probó Hack Nerd Font pero las letras se recortaban ("no completas") por sus métricas + el `adjust_line_height -4`, así que volvió JetBrainsMono y se quitó el `-4` → glifos completos.
- **`background #000000` al final**: pedido ("negro total"); gana sobre la theme porque kitty aplica la última definición, y `kitten themes` no lo pisa al regenerar el include.
- **`background_opacity 0.80`**: deja asomar el wallpaper/blur detrás sin perder contraste.
- **`Ctrl+Shift+flechas`**: `Ctrl+flechas` ya lo tiene sxhkd a nivel WM; los shifts navegan los splits del propio kitty sin colisión.

---

## 7. Shell (red y root) — `~/.zshrc` y `/root/.zshrc`

**Configurado así (bloque añadido al final, con backup):**
```sh
alias ls='lsd'                 # listados con iconos/colores
alias ll='lsd -la --icon always'
alias lt='lsd --tree --icon always'
alias cat='batcat --paging=never'
alias fetch='fastfetch'
export BAT_THEME="Catppuccin Mocha"

[[ ! -f ~/powerlevel10k/powerlevel10k.zsh-theme ]] || source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

**Por qué:**
- `batcat` (no `bat`): en Kali/Debian el binario se llama así — sin el alias, `cat` no tendría colores.
- `BAT_THEME=Catppuccin Mocha`: tema de alto contraste que combina con kitty.
- p10k por `git clone` (no está en apt, y sin oh-my-zsh por peso). Config Rainbow precargada para que el asistente no moleste.
- El highlight va **después** del theme (requisito de p10k).
- fastfetch solo bajo demanda (`fetch`) — no automático, decisión pendiente de confirmar.

---

## 8. nvim + NvChad (nuevo)

**Configurado así:**
- nvim 0.12.3 + ripgrep + tree-sitter-cli (apt)
- NvChad vía **`NvChad/starter`** en `~/.config/nvim` (red) y `/root/.config/nvim` (root), sin `.git`
- 27 plugins con lazy.nvim por usuario · parsers base ya compilados · LSPs bajo demanda con `:Mason`
- **Copilot (red + root)**: `copilot.vim` (autocompletado inline) + `CopilotChat.nvim` (chat)

**Por qué:**
- **`starter` no `NvChad` a secas**: es el método oficial actual (NvChad va como plugin de lazy.nvim).
- **tree-sitter-cli** es requisito del nvim-treesitter (parsers); **ripgrep** para el grep de Telescope.
- **Fuente no-Mono**: hace que los iconos de NvChad se vean más grandes.
- **`nvim --headless "+Lazy! sync" +qa`**: pre-instaló los plugins sin abrir la UI. Como el starter ya no trae `:MasonInstallAll`, los LSPs se añaden con `:Mason` cuando el lenguaje lo pida.
- **copilot.vim**: el usuario pidió el texto fantasma inline oficial. Se desactiva su **Tab** (`copilot_no_tab_map`) porque NvChad ya usa Tab para el menú cmp; aceptar la sugerencia es con **`Ctrl+L`**, ciclar con `Alt+]`/`Alt+[`.
- **CopilotChat.nvim**: el "ayuda", detecta copilot.vim como backend. Se abre con **`<Space>cc`** o `:CopilotChat` (+ prompts `Explain/Review/Fix/Docs`). Sin `build tiktoken` (conteo de tokens aproximado; no bloquea).
- Líder = `Space` · tema por defecto de NvChad (cambiar con `Space+Th`).

> **PENDIENTE manual del usuario**: hacer `:Copilot auth` en nvim (red y root) → código → `github.com/login/device`. Sin eso Copilot no responde.

## 9. Wallpaper

- `~/Pictures/retro1.png` con `feh --bg-fill --no-fehbg` (en bspwmrc).
- **Por qué `--bg-fill`**: la imagen (2912×1632) cubre tu pantalla (1562×766) recortando; `--no-fehbg` evita el mini-autostart de feh. feh pinta y sale (no es daemon) → 0% CPU en reposo.

---

## 10. Rendimiento medido (reposo)

| Proceso | CPU | RAM |
|---|---|---|
| bspwm | 0.0% | ~2.6 MB |
| sxhkd | 0.0% | ~2.4 MB |
| picom | ~1.5% | ~9 MB |
| polybar | ~2.0% | ~20 MB |

**Umbral de alerta:** si picom pasa de ~6-7% CPU al mover ventanas → bajar `blur-strength` a 3 o `blur-method "none"`.

---

## 11. Resize de la ventana VM (Super+Shift+R)

- `~/.config/bspwm/vm-resize.sh` + atajo `super + shift + r` en sxhkdrc.
- Con un WM tiling las VMware Tools solo marcan el nuevo tamaño como "preferred"; `xrandr --auto` lo activa, RandR emite `monitor_geometry` y bspwm re-dibuja solo. Polybar se relanza aparte (su ancho no se auto-ajusta).
- Fix extra: `pgrep -u "$(id -u)"` en bspwmrc y vm-resize.sh (`$UID` no existe en `sh`, daba usage de pgrep).

## 12. Cómo recargar cada pieza

| Cambio en | Recargar con |
|---|---|
| bspwmrc / polybar / bordes / gap | `Super+Alt+r` |
| sxhkdrc | `Super+Escape` |
| picom.conf | `pkill -x picom && bspc wm -r` |
| kitty.conf / fuente | `Ctrl+Shift+F5` |
| .zshrc / bat / p10k | terminal nueva |

---

## 12. Pendientes (no ejecutado)

- fastfetch automático al abrir terminal / logo personalizado.
- `fzf` (Ctrl+R fuzzy) y/o `zoxide` — ofrecidos, no aceptados.
- Compactar filas de kitty de nuevo (`adjust_line_height -2` como máximo) si el layout se ve espacioso.