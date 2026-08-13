# manual.md — ¿Qué está instalado, cómo se instala y cómo está configurado manualmente?

> Manual de referencia del entorno **Kali + bspwm**. Este documento responde a:
> **qué** está instalado, **cómo** se instaló (método exacto) y **dónde / cómo** está
> configurado manualmente dentro de cada archivo del repo (`dotfiles/`).
>
> El `install.sh` automatiza todo lo de este documento (ver §8). El "por qué" de cada valor
> está en `docs/actual.md` y `docs/entorno.md`.

---

## 1. Resumen del sistema

| Aspecto | Valor |
|---|---|
| Distro | Kali GNU/Linux Rolling 2026.3 (VM, GPU virtual VMware SVGA II) |
| WM / stack | bspwm 0.9.12 · sxhkd 0.6.3 · polybar 3.7.2 · picom 13 · kitty 0.47.3 |
| Launcher | rofi 2.0.0 (`Super+D`) |
| Shell | zsh 5.9 (red y root) |
| Editor | nvim 0.12.3 + NvChad v2.5 (starter) |
| Teclado | `latam` |
| Hora | America/Lima |

> Regla de oro del entorno: como la GPU es virtual, **nada de OpenGL** → picom usa
> `xrender`, cero animaciones, blur ligero `dual_kawase`.

---

## 2. Paquetes instalados (apt) — versión y para qué

Instalados con `sudo apt install` (todos de los repos de Kali/Debian salvo el driver X).

| Paquete | Versión | Rol |
|---|---|---|
| `bspwm` | 0.9.12 | Window manager tiling |
| `sxhkd` | 0.6.3 | Daemon de atajos de teclado |
| `polybar` | 3.7.2 | Barra de estado (módulos internos) |
| `picom` | 13 | Compositor: sombras, esquinas, blur, opacidad |
| `kitty` | 0.47.3 | Terminal |
| `rofi` | 2.0.0 | Lanzador de aplicaciones (`Super+D`) |
| `xclip` | 0.13-4 | Portapapeles CLI (clic en el módulo *target* de polybar) |
| `zsh` | 5.9 | Shell por defecto |
| `zsh-syntax-highlighting` | 0.8.0 | Comandos coloreados al tipear |
| `zsh-autosuggestions` | 0.7.1 | Sugerencias grises del historial |
| `lsd` | 1.2.0 | `ls`/`ll`/`lt` con iconos |
| `bat` | 0.26.1 | `cat` con resaltado → alias **`batcat`** |
| `fastfetch` | 2.66.0 | Info del sistema bajo demanda (`alias fetch`) |
| `feh` | 3.12.2 | Visor/fondo (histórico; ya no se usa para el wallpaper) |
| `xwallpaper` | 0.7.6 | Fondo que **repinta solo ante RandR** (`--daemon`) |
| `x11-xserver-utils` | 7.7+11 | `xrandr`, `setxkbmap`, `xsetroot` |
| `nvim` (neovim) | 0.12.3 | Editor (NvChad sobre lazy.nvim) |
| `ripgrep` | 15.2.0 | Búsqueda de Telescope (NvChad) |
| `tree-sitter-cli` | 0.26.8 | Compilar parsers de nvim-treesitter |
| `open-vm-tools` | 13.0.10 | Agente invitado (clipboard, resize host→guest, heartbeat) |
| `open-vm-tools-desktop` | 13.0.10 | Agente GUI `vmware-user` (portapapeles + resize en sesión gráfica) |
| `xserver-xorg-video-vmware` | 13.3.0 | **Driver X de VMware** (resize de la VM). **No está en Kali** → se instala desde Debian bookworm (ver §3) |

Dependencias del instalador (suele traerlas Kali, pero el script las usa): `curl`, `unzip`, `git`.

---

## 3. Cómo se instaló cada pieza (método exacto)

### 3.1 Paquetes de repos (una sola línea)
```sh
sudo apt update
sudo apt install -y bspwm sxhkd polybar picom kitty rofi xclip \
    zsh zsh-syntax-highlighting zsh-autosuggestions \
    lsd bat fastfetch xwallpaper x11-xserver-utils \
    ripgrep tree-sitter-cli nvim \
    open-vm-tools open-vm-tools-desktop
```

### 3.2 Driver X de VMware (desde Debian bookworm)
Kali dejó de compilar `xserver-xorg-video-vmware`; con el fallback `modesetting` + VMware
Workstation 25.x los eventos de resize/EDID se pierden (Kali BTS #9496). Se instala con
**source temporal** de bookworm y se borra:

```sh
echo "deb http://deb.debian.org/debian bookworm main contrib non-free" | sudo tee /etc/apt/sources.list.d/tmp-debian-bookworm.list
sudo apt update
sudo apt install -y xserver-xorg-video-vmware
sudo rm /etc/apt/sources.list.d/tmp-debian-bookworm.list && sudo apt update
```
Tras esto **reiniciar lightdm** (`systemctl restart lightdm`) para que Xorg cargue `vmware_drv.so`.
Detalle completo: `docs/vmtools.md`.

### 3.3 Fuente JetBrainsMono Nerd Font (descarga de GitHub)
```sh
curl -fL -o /tmp/JBM.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o -q /tmp/JBM.zip -d ~/.local/share/fonts
fc-cache -f
```
Instala las variantes `JetBrainsMono Nerd Font` (no-Mono, la activa), `...Mono` y `...Propo`.
Requisito para los iconos de **lsd** y los glifos del prompt **powerlevel10k** (también usada en polybar).

### 3.4 powerlevel10k (git clone — NO está en apt)
```sh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```
Config del tema **Rainbow** en `~/.p10k.zsh` (y copiada a `/root/`), precargada para que el
asistente de configuración no moleste.

### 3.5 NvChad + plugins (método oficial: `NvChad/starter`)
- La config de `~/.config/nvim` es el **starter oficial** (NvChad v2.5 va como plugin de lazy.nvim).
- Se instala clonando el starter y los plugins se descargan solos (lazy.nvim) al primer arranque:
```sh
git clone --depth=1 https://github.com/NvChad/starter ~/.config/nvim   # (sin .git)
# luego, para no abrir la UI:
nvim --headless "+Lazy! sync" +qa
```
- **LSPs**: se instalan bajo demanda con `:Mason` (el starter actual ya **no** trae `:MasonInstallAll`).
- **Parsers treesitter** compilados: `lua, luadoc, printf, vim, vimdoc, python, bash, c, html, css, json, yaml, markdown, markdown_inline, javascript` (más en nvim con `:TSInstall <lang>`).

### 3.6 Copilot (nvim) — plugins de GitHub
- **`github/copilot.vim`**: autocompletado inline. Instalado por lazy.nvim (no build).
- **`CopilotC-Nvim/CopilotChat.nvim`**: chat con Copilot (`<Space>cc` o `:CopilotChat`), detecta copilot.vim como backend.
- **Auth manual obligatoria**: `:Copilot auth` en nvim (red y root) → código → `github.com/login/device`. Sin esto Copilot no responde.

### 3.7 Tema de kitty (Catppuccin Mocha)
```sh
kitten themes "Catppuccin-Mocha"   # escribe "include current-theme.conf" al final de kitty.conf
```
El fondo `#000000` (override al final del archivo) gana sobre la theme porque kitty aplica la **última** definición.

---

## 4. Archivos de configuración — dónde están en el repo y en el sistema

Todo lo de `config/` se copia a `~/.config/` y lo de `home/` a `~` (ver `install.sh` → §8).

| Repo (`dotfiles/`) | Sistema | Qué es |
|---|---|---|
| `config/bspwm/bspwmrc` | `~/.config/bspwm/bspwmrc` | WM: 5 escritorios, bordes, gap, autostart |
| `config/sxhkd/sxhkdrc` | `~/.config/sxhkd/sxhkdrc` | Atajos de teclado |
| `config/polybar/config.ini` | `~/.config/polybar/config.ini` | Barra de estado |
| `config/polybar/vpn.sh` | `~/.config/polybar/vpn.sh` | Script del módulo **vpn** (lee `tun0`) |
| `config/polybar/target.sh` | `~/.config/polybar/target.sh` | Script del módulo **target** (muestra `target.txt`) |
| `config/picom/picom.conf` | `~/.config/picom/picom.conf` | Compositor (xrender + blur) |
| `config/kitty/kitty.conf` + `current-theme.conf` | `~/.config/kitty/` | Terminal |
| `config/rofi/config.rasi` | `~/.config/rofi/config.rasi` | Tema del launcher (Arc-Dark) |
| `config/nvim/**` | `~/.config/nvim/**` | NvChad (init.lua, chadrc.lua, lua/*, lazy-lock.json) |
| `home/.zshrc` | `~/.zshrc` (y → `/root/.zshrc`) | Shell: lsd, batcat, p10k, plugins |
| `home/.p10k.zsh` | `~/.p10k.zsh` (y → `/root/.p10k.zsh`) | Prompt powerlevel10k (Rainbow) |
| `home/.gitconfig` | `~/.gitconfig` | `color.ui = true` |
| — | `~/powerlevel10k/` | Repo del tema (clonado, no es config) |
| — | `~/Pictures/` | Imágenes del wallpaper rotativo (`retro1.png`, `fondo*.png/jpg`) |
| — | `~/.local/share/fonts/` | JetBrainsMono Nerd Font |
| — | `~/.local/share/nvim/lazy/` | Plugins de NvChad (lazy.nvim) |

---

## 5. Qué está configurado manualmente dentro de cada archivo

### 5.1 `bspwmrc` — el script maestro del WM
- `setxkbmap -layout latam` → teclado latinoamericano.
- **Wallpaper rotativo** (loop inline): recorre TODAS las imágenes de `~/Pictures` (filtro `case` por extensión png/jpg/jpeg, descarta `.Zone.Identifier`), lanza `xwallpaper --daemon --zoom` y cambia cada **60 s**. `--daemon` = escucha RandR y repinta solo ante el resize de la VM. Marcador `WALLROT` en el cmdline = guarda anti-duplicado.
- `bspc monitor -d 1 2 3 4 5` → 5 escritorios (coinciden con `Super+[1-5]`).
- Bordes: `border_width 1`; enfocada **blanco** `#ffffff`, resto gris `#30302f`. `window_gap 8`.
- Monoclo (`single_monocle` etc.) → las ventanas llenan el escritorio sin huecos.
- **Autostart con guardas** `pgrep`/`pkill` (evita duplicados al reiniciar con `Super+Alt+r`):
  - `sxhkd` y `picom` → solo si no están corriendo.
  - `polybar` → detección del monitor por `xrandr` → `export MONITOR` (sin hardcodear el nombre).
  - **Loop resize de polybar**: `bspc subscribe monitor_geometry | while read...` relanza polybar sola cuando cambia la resolución.
  - `vmware-user-suid-wrapper` → agente GUI de VMware Tools (portapapeles + resize host↔guest), con guarda.

### 5.2 `sxhkdrc` — atajos
| Atajo | Acción |
|---|---|
| `Super+Enter` | kitty |
| `Super+Q` | cerrar ventana enfocada |
| `Super+Space` | toggle tiling/floating |
| `Super+1..5` | cambiar de escritorio |
| `Super+Shift+1..5` | mover la ventana enfocada al escritorio (`bspc node -d`) |
| `Ctrl+↓↑←→` | mover foco entre ventanas (bspwm) |
| `Super+Escape` | recargar sxhkd (`pkill -USR1`) |
| `Super+Alt+Q` / `Super+Alt+R` | salir / reiniciar bspwm |
| `Super+Shift+R` | `bspc wm -r` (recarga bspwm solo, más suave) |
| `Super+D` | **rofi** `-show drun` |

### 5.3 `polybar/config.ini` — barra negra/blanca
- Fuente **JetBrainsMono Nerd Font** `size=10;2`, `height 26`, bordes finos, sin tray.
- Módulos: `workspaces cpu memory net vpn target date` (todos internos salvo vpn/target).
- **Workspaces como círculos**: `●` ocupado/foco (blanco, foco con underline) · `○` vacío (gris). Separador triple espacio.
- **vpn** (`custom/script` → `vpn.sh`): lee `tun0`; IP en **verde** si hay VPN, `VPN disconnected` en gris si no.
- **target** (`custom/script` → `target.sh`): muestra `~/.config/polybar/target.txt` en **rojo** (o `target: none`); **clic izquierdo** copia el valor al portapapeles con `xclip`.
- **net**: solo `IP %local_ip%` (variable interna, sin scripts); **date** con `date`+`time` separados (bug resuelto).

### 5.4 `picom.conf` — compositor "pensado para la VM"
- `backend = "xrender"` (**la clave**: evita llvmpipe/GL por software) y `vsync = false`.
- `corner-radius 12` con `corner-radius-rules` que dejan **rectos** la barra, docks, menús y fullscreen.
- Opacidad: enfocada `0.90` / inactiva `0.80` → el blur se ve a través de las ventanas inactivas.
- Blur `dual_kawase` (el más ligero) con `blur-strength 5`; excluye barra/dock/desktop.
- Sombras suaves (`shadow-opacity 0.20`), fading OFF, `unredir-if-possible true`, log en `/tmp/picom.log`.
- Sintaxis libconfig: comentarios `#`/`//` (no `;`), listas entre comillas.

### 5.5 `kitty.conf` — terminal
- `font_family JetBrainsMono Nerd Font` (variante **no-Mono**, recomendada por NvChad) · `font_size 10`.
- `background_opacity 0.90` (dinámica: `Ctrl+Shift+O`), fondo **negro total `#000000`** (override al final, tras el include de la theme).
- Splits internos: `Ctrl+Shift+↑↓←→` (mover foco) · nuevo split con `Ctrl+Shift+Enter`.
- **Multi-clipboard F1-F4**: `F1` copia/`F2` pega al buffer del sistema; `F3`/`F4` al buffer privado `cb2`.
- `map ctrl+shift+flechas → neighboring_window` (no choca con `Ctrl+flechas` de sxhkd a nivel WM).

### 5.6 `rofi/config.rasi`
```rasi
@theme "/usr/share/rofi/themes/Arc-Dark.rasi"
```
Tema por defecto del launcher (solo `@theme`; el resto, comportamiento stock).

### 5.7 `home/.zshrc` (red y root)
```sh
alias ls='lsd'
alias ll='lsd -la --icon always'
alias lt='lsd --tree --icon always'
alias cat='batcat --paging=never'     # en Kali el binario es "batcat", no "bat"
alias fetch='fastfetch'
export BAT_THEME="Catppuccin Mocha"
[[ ! -f ~/powerlevel10k/powerlevel10k.zsh-theme ]] || source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```
El highlight va **después** del theme (requisito de p10k). fastfetch solo bajo demanda.

### 5.8 `home/.gitconfig`
```ini
[color]
	ui = true
```
(Diffs/estado de git con color.)

### 5.9 `config/nvim` — NvChad
- `init.lua` → lazy.nvim; `lua/chadrc.lua` → tema **bearded-arc** + `transparency = true` (nvim hereda el negro del terminal) + `tabufline` siempre visible (`lazyload = false`).
- `lua/options.lua` → `termguicolors = true` (necesario para colorizer).
- `lua/plugins/init.lua` → treesitter con parsers (base: lua, python, bash, c, markdown, etc.) + **`nvim-colorizer.lua`** (muestra los códigos de color con su color real).
- `lua/mappings.lua` → `Ctrl+L` = `copilot-accept-line` (pisa el default de NvChad que usaba `Ctrl+L` para moverse).
- `configs/lspconfig.lua`, `conform.lua`, `lazy.lua` → defaults del starter.
- Líder = `Space`. Todos los atajos reales: `shortcuts-nvim.md`.

### 5.10 Scripts auxiliares de polybar
- **`vpn.sh`**: `ip -4 addr show tun0` → si hay IP imprime `VPN <IP>` en verde (`%{F#00ff87}`); si no, `VPN disconnected` en gris.
- **`target.sh`**: lee `~/.config/polybar/target.txt` → lo muestra en rojo (`%{F#f38ba8}`) o `target: none` en gris. El valor se escribe a mano (`echo "IP" > ~/.config/polybar/target.txt`) y se limpia con la barra en vacío; el clic copia con `xclip`.

---

## 6. Scripts / automáticos que NO son config (no van al repo)

| Ruta | Qué es |
|---|---|
| `~/powerlevel10k/` | Repo clonado del theme (se descarga con install.sh) |
| `~/.local/share/fonts/` | Fuente Nerd (se descarga con install.sh) |
| `~/.local/share/nvim/` | Plugins de lazy.nvim (se generan solos) |
| `~/.config/polybar/target.txt` | Runtime del módulo target (gitignored) |
| `.bak`/`.orig` | Backups que crea install.sh (gitignored) |

---

## 7. Cómo recargar cada pieza tras editarla

| Cambio en | Recargar con |
|---|---|
| `bspwmrc` / polybar / bordes / gap | `Super+Alt+r` (reinicia bspwm; la barra y el wallpaper solos) o `Super+Shift+R` (solo bspwm) |
| `sxhkdrc` (atajos) | `Super+Escape` |
| `picom.conf` | `pkill -x picom && bspc wm -r` |
| `kitty.conf` / fuente / tema | `Ctrl+Shift+F5` o nueva terminal |
| `.zshrc` / bat / p10k | **terminal nueva** |
| `nvim` (config/plugins) | reabrir nvim (lazy.nvim auto-sync) |

---

## 8. Instalación automática (`install.sh`)

El script del repo automatiza TODO lo de arriba (idempotente; respalda lo existente como `*.bak`):

```sh
git clone https://github.com/bryanzsh/dotfiles.git && cd dotfiles
./install.sh            # usuario actual
sudo ./install.sh --root   # además replica en /root
```

Qué hace paso a paso:
1. `apt update` + instala **todos** los paquetes de §2 (incluye `rofi`, `xclip`).
2. Instala el **driver VMware** desde Debian bookworm (si falta `vmware_drv.so`).
3. Descarga **JetBrainsMono Nerd Font** → `~/.local/share/fonts` + `fc-cache`.
4. Clona **powerlevel10k** → `~/powerlevel10k`.
5. Copia `config/*` → `~/.config/` (bspwm, sxhkd, kitty, polybar, picom, nvim, rofi) y `home/.zshrc`, `home/.p10k.zsh`, `home/.gitconfig` → `~` (con backups).
6. Crea `/usr/share/xsessions/bspwm.desktop` si falta (sesión bspwm en lightdm).
7. **Bootstrap de NvChad**: `nvim --headless "+Lazy! sync" +qa` tras copiar configs → plugins instalados sin abrir la UI.
8. `--root` replica las configs en `/root` (con sudo).
9. `notes()` recuerda los pasos manuales: LSPs con `:Mason`, `:Copilot auth`, wallpaper en `~/Pictures/`.

> Los únicos pasos **no** automatizables (por requerir cuenta/credencial) son: `:Mason` (bajo demanda) y `:Copilot auth`.

---

## 9. Verificación del estado

```sh
ps -o pid,comm,%cpu,rss -C bspwm -C sxhkd -C picom -C polybar   # stack vivo, sin duplicados
glxinfo -B | grep -i renderer                                    # NO debe decir llvmpipe (si instalas mesa-utils)
pgrep -f 'bspc subscribe monitor_geometry'                       # loop resize de polybar
pgrep -f WALLROT                                                 # loop de wallpaper rotativo
pgrep -f vmware-user                                             # agente VMware Tools
grep -m1 'Matched vmware' /var/log/Xorg.0.log                    # driver X correcto
tail -f /tmp/picom.log                                           # log del compositor
```
Umbral: picom en reposo ~0.5-2 % CPU; si pasa de ~6-7 % al mover ventanas → bajar `blur-strength` a 3 o `blur-method "none"`.