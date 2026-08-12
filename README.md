# dotfiles — Entorno bspwm (Kali Linux)

Configuraciones de mi entorno de escritorio **ligero, estable y de bajo consumo** para
**Kali Linux** en una VM (bspwm + sxhkd + polybar + picom + kitty + nvim).

> Todo el "por qué" de cada valor está documentado en `docs/actual.md` y `docs/entorno.md`.

## Incluye

| Área | Archivos |
|---|---|
| WM | `config/bspwm/bspwmrc` (wallpaper xwallpaper --daemon + loop polybar en resize) |
| Atajos | `config/sxhkd/sxhkdrc` |
| Terminal | `config/kitty/` (tema Catppuccin Mocha + negro total) |
| Barra | `config/polybar/config.ini` (black/white, CPU/RAM/IP/fecha) |
| Compositor | `config/picom/picom.conf` (blur `dual_kawase`, backend `xrender`) |
| Editor | `config/nvim/` (NvChad + Copilot) |
| Shell | `home/.zshrc`, `home/.p10k.zsh` (lsd, bat, powerlevel10k) |
| Docs | `docs/` (actual.md, AGENTS.md, entorno.md) |

## Instalación automática

```bash
git clone https://github.com/bryanzsh/dotfiles.git
cd dotfiles
./install.sh            # instala packages + fuentes + p10k + configs
# opcional: también replica en /root
sudo ./install.sh --root
```

El script es **idempotente**: respalda los archivos existentes como `*.bak` y no rompe nada
si lo ejecutas de nuevo.

### Después de instalar
1. Reinicia la sesión y elige **bspwm** en lightdm.
2. En nvim: instala LSPs con `:Mason` (bajo demanda) y activa Copilot con `:Copilot auth`.
3. Pon tu wallpaper en `~/Pictures/retro1.png` (xwallpaper lo carga).
4. Si estás en VMware Workstation 25.x, el instalador trae el driver `xserver-xorg-video-vmware`
   desde Debian bookworm para que el resize de la VM funcione (Kali lo dejó de compilar).
   El fondo (`xwallpaper --daemon`) y polybar siguen al resize automáticamente.

## Atajos principales

| Atajo | Acción |
|---|---|
| `Super+Enter` | abrir kitty |
| `Super+Q` | cerrar ventana enfocada |
| `Super+Space` | tiling / floating |
| `Super+1..9` | cambiar de escritorio |
| `Super+Shift+1..9` | mover ventana al escritorio |
| `Ctrl+↓↑←→` | mover foco (bspwm) |
| `Ctrl+Shift+↓↑←→` | mover foco entre splits de kitty |
| `Super+Alt+R` | reiniciar bspwm |
| `Super+Escape` | recargar sxhkd |

## Notas VM
- **Picom usa backend `xrender`** (GPU virtual → nada de GL por software).
- Blur ligero (`dual_kawase`); si la CPU sube de ~6-7% al mover ventanas, baja
  `blur-strength` a 3 o pon `blur-method = "none"`.
- **Resize automático**: con `vmware_drv.so` bspwm retila solo ante `monitor_geometry`;
  `xwallpaper --daemon` repinta el fondo y un loop `bspc subscribe monitor_geometry`
  relanza polybar. Cero scripts de resize.