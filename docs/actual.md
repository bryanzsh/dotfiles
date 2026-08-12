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
- 5 escritorios `1..5` (en la barra se ven como **5 círculos**: `●` ocupado / `○` vacío)
- `border_width 1` · borde de la ventana enfocada **blanco** (`#ffffff`), resto gris `#30302f`
- `window_gap 8`
- Teclado latam · wallpaper **xwallpaper --daemon** · autostart con guardas `pgrep`/`pkill`
- Monitor de polybar detectado por `xrandr` (sin hardcodear)
- **Loop `bspc subscribe monitor_geometry`** (inline) que relanza polybar al cambiar la resolución

**Por qué:**
- 5 escritorios → coinciden con `Super+[1-5]` y `Super+Shift+[1-5]`; los círculos dan un indicador compacto: relleno blanco = ocupado/foco, hueco = vacío.
- Borde blanco de 1px → resalta la ventana enfocada (la que controla `Ctrl+flechas`) sin pesadez visual.
- `gap 8` → se bajó de 12 para un layout compacto que aproveche la pantalla.
- Guardas anti-duplicado → bspwmrc se re-ejecuta en `Super+Alt+r`; sin `pgrep` habría dobles procesos (doble RAM/CPU).
- Monitor dinámico → el nombre cambia entre tu VM, otras VMs y Xvfb; hardcodearlo rompe la barra.
- Loop de resize → al achicar/expandir la ventana de la VM, polybar no ajusta su ancho sola (width=% se calcula al arrancar); el `bspc subscribe monitor_geometry` la relanza sola, estilo s4vitar (cero scripts).

---

## 3. Atajos — `~/.config/sxhkd/sxhkdrc`

| Atajo | Acción |
|---|---|
| `Super+Enter` | abre kitty |
| `Super+Q` | cierra ventana enfocada |
| `Super+Space` | toggle tiling/floating |
| `Super+1..5` | cambia de escritorio |
| `Super+Shift+1..5` | **mueve la ventana enfocada** al escritorio |
| `Ctrl+↑↓←→` | mueve el foco entre ventanas (bspwm) |
| `Super+Escape` | recarga sxhkd |
| `Super+Alt+Q` / `Super+Alt+R` | salir / reiniciar bspwm |

**Por qué:**
- `Super+Shift+[1-5]` usa `bspc node -d` (mueve el **nodo**), distinto de `bspc desktop -f` (solo cambia). → con 2 ventanas, enfocas una y la mandas al escritorio que elijas.
- `Ctrl+flechas` asumió el conflicto con el salto de palabra en terminales (readline) porque priorizas navegar ventanas sin mouse. Cambiar a `super` es 1 línea si molesta.

---

## 4. Polybar — `~/.config/polybar/config.ini`

**Configurado así:**
- Barra **negra** (`#000000`) con texto **blanco** (`#ffffff`)
- **5 workspaces como círculos**: `●` foco/ocupados (blanco, foco con underline) y `○` vacíos (gris `#666666`)
- Compacta: `height 20` · fuente `DejaVu Sans Mono:size=8` · paddings/márgenes mínimos
- Módulos: workspaces · CPU · RAM · **IP eth0** · fecha/hora (hora del sistema en **America/Lima**)
- Sin tray (desactivado a propósito)

**Por qué:**
- Círculos → indicador compacto y minimalista; relleno blanco = hay ventanas (ocupado/foco), hueco = escritorio vacío.
- Negro/blanco → máximo contraste; el foco se distingue por el underline.
- Módulos todos `internal/*` (sin scripts) → consumo mínimo (~2% CPU, sin procesos hijos).
- La IP sale con `%local_ip%` (variable interna de polybar 3.7.2) → cero scripts externos.
- Fecha/hora peruana: se cambió la zona horaria del sistema a `America/Lima` (`timedatectl set-timezone America/Lima`), polybar la refleja al instante.
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

- **Rotativo:** loop inline en `bspwmrc` que muestra en bucle **todas** las imágenes de `~/Pictures`, cambiando cada 60s. Filtro `case` (png/jpg/jpeg) que descarta `.Zone.Identifier`.
- Cada ciclo usa **`xwallpaper --daemon --zoom "$img"`** (repinta solo ante resize).
- **Por qué `--zoom`**: equivale a `--bg-fill` de feh — la imagen cubre la pantalla recortando según el aspect ratio.
- **Por qué `--daemon`**: xwallpaper se queda escuchando **eventos RandR** y **repinta solo** el fondo cuando cambia la resolución (achicar/expandir la VM). feh pintaba una sola vez y quedaba desalineado con el resize. CPU en reposo ~0% (solo despierta ante RandR).
- **Por qué rotativo**: prioridad del usuario — que el fondo varie cada minuto entre todas las imágenes de Pictures, sin scripts (estilo s4vitar). Guarda `pgrep -f WALLROT` anti-duplicado en `Super+Alt+r`.

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

## 11. Resize de la VM (resuelto, cero scripts)

- **Driver X:** `xserver-xorg-video-vmware` desde Debian bookworm (Kali lo dejó de compilar). Con `modesetting` + VMware Workstation 25.x los eventos de resize/EDID llegan tarde o se pierden (Kali BTS #9496); con `vmware_drv.so` Xorg maneja los modos y bspwm re-tila solo ante `monitor_geometry`.
- **Ya NO existe `vm-resize.sh` ni `Super+Shift+R`** (estilo s4vitar: cero scripts).
- **Fondo:** `xwallpaper --daemon` repinta automático (rotativo: todas las imágenes de `~/Pictures` cada 60s).
- **Polybar:** loop inline en `bspwmrc`: `bspc subscribe monitor_geometry | while read -r _; do pkill -x polybar; polybar -r main &; done` (guarda `pgrep -f` anti-duplicado). Su ancho no se auto-ajusta si no se relanza.
- Fix aplicado: `pgrep -u "$(id -u)"` (`$UID` no existe en `sh`, daba usage).

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