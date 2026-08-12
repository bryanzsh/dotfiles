# Estado del sistema — Kali Linux (VM) + bspwm

Resumen de la configuración persistente del equipo para retomar el trabajo con contexto.

## Hardware / Base
- **Kali GNU/Linux Rolling 2026.3** · VM con **GPU virtual VMware SVGA II** (sin aceleración HW real).
- 4 vCPU / 15 GiB RAM · Display manager **lightdm** · Sesión gráfica: **bspwm** sobre X11.
- Terminal: **kitty** · Shell: **zsh** · Teclado: `latam`.

## Entorno bspwm — archivos de config
| Archivo | Contenido |
|---|---|
| `~/.config/bspwm/bspwmrc` | escritorios 1-9, gap 8, border 1, borde de foco blanco, teclado latam, wallpaper feh, autostart con guardas `pgrep`/`pkill` |
| `~/.config/sxhkd/sxhkdrc` | atajos (ver abajo) |
| `~/.config/picom/picom.conf` | backend `xrender` (clave en VM), esquinas 12px, blur `dual_kawase` 5, active-opacity 0.90, inactive-opacity 0.80, log `/tmp/picom.log` |
| `~/.config/polybar/config.ini` | barra negra, texto blanco, workspace enfocado invertido (blanco/negro), CPU/RAM/IP eth0/fecha-hora, monitor auto (env `MONITOR` desde bspwmrc) |
| `~/.config/kitty/kitty.conf` | font 10, opacidad 0.80, tema Catppuccin Mocha con fondo override `#000000`, font **JetBrainsMono Nerd Font** (variante no-Mono, recomendada por NvChad; Hack Nerd queda en `/usr/share/fonts/truetype/hacknerd` si se usa), navegación de splits ctrl+shift+flechas, sin `adjust_line_height` (evita letras recortadas) |

## Atajos de teclado
- `Super+Enter` → kitty · `Super+Q` → cerrar ventana · `Super+Space` → toggle tiling/floating
- `Super+1..9` → cambiar escritorio · `Super+Shift+1..9` → mover la ventana enfocada a ese escritorio · `Super+Shift+R` → reencajar desktop a la resolución nueva de la VM (`vm-resize.sh`: `xrandr --auto` + relanza polybar) · `Super+Escape` → recargar sxhkd · `Super+Alt+r` → reiniciar bspwm/picom · `Super+Alt+q` → salir
- `Ctrl+flechas` → cambiar foco entre ventanas de **bspwm** (borde blanco en la activa)
- `Ctrl+Shift+flechas` → mover foco entre **splits dentro de kitty** · `Ctrl+Shift+Enter` → nuevo split
- `Ctrl+Shift+F5` → recargar config de kitty · `Ctrl+Shift+O` → opacidad en vivo

## Terminal bonita (red y root)
- **lsd** (`ls`/`ll`/`lt` con iconos) · **batcat** como `cat` con `BAT_THEME=Catppuccin Mocha`
- **powerlevel10k** tema Rainbow (clonado en `~/powerlevel10k`, config `~/.p10k.zsh` y `/root/.p10k.zsh`)
- **zsh-syntax-highlighting + zsh-autosuggestions** (rutas apt)
- **fastfetch** disponible como `fetch` (bajo demanda, no automático)
- Backups creados por opencode: `~/.zshrc.bak.opencode`, `/root/.zshrc.bak.opencode`, `kitty.conf.bak`, etc.

## nvim + NvChad (red y root)
- **nvim 0.12.3** + ripgrep + tree-sitter-cli (apt). NvChad instalado vía **`NvChad/starter`** (método oficial): `~/.config/nvim` y `/root/.config/nvim` (sin `.git`).
- Plugins con lazy.nvim: en `~/.local/share/nvim/lazy` y `/root/.local/share/nvim/lazy`.
- Parsers treesitter base compilados (`lua, luadoc, printf, vim, vimdoc`). LSPs se instalan bajo demanda con `:Mason`.
- OJO: el starter actual **ya no define `:MasonInstallAll`** (doc vieja); LSPs a mano con `:Mason`.
- **GitHub Copilot instalado (red + root)**: `github/copilot.vim` (autocompletado inline; NvChad usa Tab para cmp → Tab de copilot desactivado, aceptar con `Ctrl+L`) + `CopilotC-Nvim/CopilotChat.nvim` (chat: `<Space>cc` o `:CopilotChat`). Auth manual: `:Copilot auth` (código → github.com/login/device). CopilotChat sin `build tiktoken` (conteo aproximado).
- Kit terminal con JetBrainsMono Nerd Font (fuente no-Mono = iconos NvChad más grandes). Cambios de config en `~/.config/nvim/lua/plugins/init.lua` + `lua/configs/`. Líder = `Space`.

## Wallpaper
- `~/Pictures/retro1.png` con `feh --bg-fill --no-fehbg` (en vivo y persistente vía bspwmrc). Antes: `xsetroot -solid`.

## Notas técnicas importantes
- **Picom en VM**: usar SIEMPRE backend `xrender` (el GL iría por llvmpipe = caro). Blur corre en CPU: en reposo ~0.5-2% CPU; si pasa de ~6-7% bajar `blur-strength`.
- **cambios de config y cómo recargar**: bspwmrc/polybar → `bspc wm -r` (polybar se relanza sola); sxhkd → `Super+Escape`; picom → `pkill -x picom`; kitty → `Ctrl+Shift+F5` o nueva terminal.
- **sudo**: requiere contraseña interactiva; sin askpass el script usa `echo '<<SUDO_PASSWORD>>' | sudo -S`.
- Polybar detecta monitor vía `xrandr` (no hardcodear nombres; usá base en Xvfb tiene nombres distintos).

## Pendiente / ideas futuras (no ejecutado)
- fzf (Ctrl+R fuzzy) y/o zoxide — ofrecidos, no aceptados aún.
- fastfetch automático al abrir terminal o logo personalizado — no decidido.

## Cómo se aplican los cambios visuales
1. kitty: `Ctrl+Shift+F5` (o reabrir).
2. bspwm + polybar + bordes: `bspc wm -r`.
3. sxhkd (nuevos atajos): `Super+Escape`.
4. Picom: `pkill -x picom && bspc wm -r`.
5. .zshrc / bat / p10k: abrir **terminal nueva**.