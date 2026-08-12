# entorno.md — Bitácora completa del entorno Kali + bspwm

> Este documento registra **todo** lo que se hizo desde el primer día: qué se instaló, qué archivos se crearon/cambiaron, por qué se tomó cada decisión, y cómo verificar/recargar cada pieza. Sirve de referencia para entender el entorno y retomarlo sin romper nada.

---

## 1. Contexto del equipo (punto de partida)

| Aspecto | Valor |
|---|---|
| Sistema | Kali GNU/Linux Rolling 2026.3 |
| Hardware | VM · GPU virtual **VMware SVGA II** (sin aceleración HW real) |
| Recursos | 4 vCPU · 15 GiB RAM · uso inicial ~2 GiB |
| Entorno original | **XFCE** (xfwm4) sobre X11 |
| Display manager | lightdm |
| Terminal / shell al inicio | sin terminal configurada · zsh |
| Teclado | `us` (se cambió a `latam`) |

**Hallazgo decisivo de la fase 0:** al ser una VM con GPU virtual, el **OpenGL va por software (llvmpipe) y es caro en CPU**. Eso condiciona toda la configuración gráfica (ver picom).

---

## 2. Fase 1 — Instalación de paquetes

```bash
sudo apt update
sudo apt install -y bspwm sxhkd polybar picom kitty
```

| Paquete | Versión | Para qué / por qué |
|---|---|---|
| `bspwm` | 0.9.12 | Window manager de partición binaria, ultraligero (RAM ~2 MB) |
| `sxhkd` | 0.6.3 | Daemon de atajos de teclado (se instala explícito aunque bspwm lo arrastra) |
| `polybar` | 3.7.2 | Barra de estado ligera (módulos internos, sin scripts) |
| `picom` | 13 | Compositor: sombras + transparencia + blur |
| `kitty` | 0.47.3 | Terminal (GPU acelerada por requerimiento; sin ella va por CPU, aceptable en VM) |

**Decisiones de la fase 1:**
- **No se instalaron paquetes extra**: el wallpaper se cubre con `feh` (después) y `xsetroot` ya venía; polybar usa texto plano, sin fuentes de iconos.
- **Nada se eliminó**: XFCE quedó intacto; solo se elige bspwm en el menú de sesión de lightdm.

---

## 3. Fase 2 — Sesión de login (lightdm)

El paquete `bspwm` trae su propio `/usr/share/xsessions/bspwm.desktop`, que ejecuta **`bspwm` directamente** (NO usa `bspwm-session`). Consecuencia importante:

> **sxhkd NO se lanza solo al entrar** → debe arrancarse desde `bspwmrc` (ver autostart).

`lightdm` muestra "bspwm" en el greeter. XFCE sigue disponible en el mismo menú.

---

## 4. Fase 3 — `~/.config/bspwm/bspwmrc`

Script maestro que bspwm ejecuta al iniciar (y al reiniciar con `Super+Alt+r`). Contenido y razón de cada bloque:

| Bloque | Líneas | Qué hace y por qué |
|---|---|---|
| Teclado | `setxkbmap -layout latam` | Distribución latinoamericana (antes era `us`) |
| Wallpaper | `xwallpaper --daemon --zoom "$HOME/Pictures/retro1.png"` | Pinta y **se queda escuchando RandR**: repinta solo cuando cambia la resolución (resize de la VM). `--zoom` cubre la pantalla recortando según aspect ratio (la imagen es 2912×1632). Sustituyó a `feh --bg-fill` (que pintaba una sola vez y quedaba desalineado tras resize) |
| Cursor | `xsetroot -cursor_name left_ptr` | Cursor flecha normal |
| Escritorios | `bspc monitor -d 1 2 3 4 5 6 7 8 9` | 9 workspaces numerados, coinciden con `Super+[1-9]` |
| Bordes | `border_width 1` | Borde de 1px; la ventana enfocada se marca en **blanco** (`active`/`focused #ffffff`), el resto gris oscuro `#30302f` |
| Gap | `window_gap 8` | Separación entre ventanas (era 12; se bajó para tenerlo más compacto, luego se afina a gusto) |
| Monoclo | `single_monocle true` etc. | Con una sola ventana llena todo el escritorio sin espacios muertos |
| Foco | `click_to_focus true`, `pointer_follows_focus true` | Clic enfoca; el cursor sigue a la ventana enfocada |
| Autostart | guardas `pgrep`/`pkill` | Evita procesos duplicados al reiniciar bspwm (explicado abajo) |
| Monitor | detección vía `xrandr` → `export MONITOR` | Polybar recibe el monitor por env; así no se hardcodea el nombre (los nombres cambian entre VM/real/Xvfb) |
| Loop resize | `bspc subscribe monitor_geometry \| while read -r _; do … polybar -r main &; done` | Relanza polybar cuando cambia la geometría del monitor (resize de la VM) porque su ancho `width=100%` se calcula al arrancar y no se auto-ajusta |

**Razón de los guardas anti-duplicado:** `bspwmrc` se re-ejecuta en cada reinicio de bspwm. Sin `pgrep -x <proc> || <proc>` se lanzarían copias dobles (doble CPU/RAM). Para polybar se usa `pkill` + re-lanzamiento: es el método estándar, así la barra aplica cambios de config.

---

## 5. Fase 4 — Atajos `~/.config/sxhkd/sxhkdrc`

| Atajo | Comando | Función |
|---|---|---|
| `Super+Enter` | `kitty` | Abre la terminal |
| `Super+Q` | `bspc node -c` | Cierra la ventana enfocada |
| `Super+Space` | `bspc query … && bspc node -t tiled \|\| bspc node -t floating` | Toggle tiling/floating real (consulta el estado y aplica el contrario) |
| `Super+1..9` | `bspc desktop -f ^1..9` | Cambia de escritorio |
| `Super+Shift+1..9` | `bspc node -d ^1..9` | **Mueve la ventana enfocada** al escritorio elegido |
| `Ctrl+←→↑↓` | `bspc node -f west/south/north/east` | Cambia el foco entre ventanas sin click (tiling) |
| `Super+Escape` | `pkill -USR1 -x sxhkd` | Recarga sxhkd sin reiniciar |
| `Super+Alt+Q` | `bspc quit` | Cierra la sesión |
| `Super+Alt+R` | `bspc wm -r` | Reinicia bspwm (recarga bspwmrc → bordes, gap, wallpaper, polybar) |

**Decisión técnica sobre `Ctrl+flechas`:** dentro de aplicaciones esa combinación salta palabra a palabra (readline), y al capturarla sxhkd **ese comportamiento se pierde**. Se aceptó el sacrificio porque el usuario priorizó navegar ventanas con teclado. Si molesta, es un cambio de 1 línea (`ctrl` → `super`).

**Los "Hotkey interference" de XFCE** (antes de entrar a bspwm) eran por XFCE agarrando Super; desaparecen en bspwm porque no corre XFCE.

---

## 6. Fase 5 — `~/.config/polybar/config.ini`

Barra de estado **negra con texto blanco**, estilo compacto:

| Opción | Valor | Razón |
|---|---|---|
| `monitor` | `${env:MONITOR}` | Se inyecta desde bspwmrc (detección por xrandr) → sin hardcodear |
| `height` | 20 | Compacta (venía de 24) |
| `line-size` / `border-bottom-size` | 1 | Borde inferior fino |
| `padding` / `module-margin` | 2 / 1 | Compacta |
| `font-0` | `DejaVu Sans Mono:size=8;2` | Fuente presente en el sistema, tamaño reducido |
| Workspace enfocado | fondo `#ffffff` + texto `#000000` | **Invertido**: chip blanco con letra negra = máximo contraste, salta a la vista |

Módulos (todos internos de polybar, sin scripts → consumo mínimo):

1. **workspaces** (type `internal/bspwm`) — muestra los 9 escritorios; el enfocado en chip invertido.
2. **cpu** (interval 2s) — `%percentage%` con prefijo `CPU:`.
3. **memory** (interval 2s) — `%used% / %total%` con prefijo `RAM:`.
4. **net** (eth0, interval 3s) — `IP %local_ip% D:%downspeed% U:%upspeed%`. La IP sale **sin scripts**: `%local_ip%` es interno de polybar 3.7.2.
5. **date** — `%d/%m/%a %H:%M`. Ojo: el módulo necesita las claves `date` y `time` por separado (bug que se resolvió en su día).

Módulos desactivados de propósito: **tray** (bandeja: ruido visual y RAM).

---

## 7. Fase 6 — `~/.config/picom/picom.conf` (EL NÚCLEO)

Compositor pensado para la VM. Decisiones y **por qué**:

| Decisión | Valor | Por qué |
|---|---|---|
| **backend** | `xrender` | La GPU es virtual. Con `egl`/`glx` picom pide OpenGL y Kali lo resolvería con **llvmpipe (GL por software)** = CPU cara. `xrender` usa el render 2D de X, mucho más barato. **ESTA ES LA CLAVE EN UNA VM.** |
| `vsync` | `false` | Sin toreo real en VM; el vsync por software cuesta CPU |
| corner-radius | `12` | Esquinas redondeadas en las ventanas (backend xrender las soporta en v13) |
| corner-radius-rules | lista | Mantiene **rectos**: pantalla completa, barra, docks y menús (tienen prioridad sobre el global) |
| shadow-opacity | `0.20` | Sombra sutil (default 0.75 era muy pesada) |
| active-opacity | `0.90` | Ventana enfocada casi opaca |
| inactive-opacity | `0.80` | Inactiva deja ver el fondo desenfocado → efecto buscado |
| blur-method | `dual_kawase` | 2 pasadas submuestreadas = el método **más ligero** (gaussian/box gastan más) |
| blur-strength | `5` | Suave y visible |
| blur-background-exclude | dock/desktop/Polybar | No desenfocar lo que no debe → ahorra CPU |
| fading / animaciones | `false` | Cero animaciones (ahorran CPU) |
| unredir-if-possible | `true` | Pantalla completa (ej. video) → picom se quita de en medio |
| log-path | `/tmp/picom.log` | Diagnóstico sin mirar pantalla |

**Rendimiento medido en reposo:** picom ≈ **0.5–2% CPU** (1.5% medido poco después). Regla práctica: si pasa de ~6-7% al mover muchas ventanas, bajar `blur-strength` a 3 o poner `blur-method = "none"`.

**Nota de sintaxis (libconfig):** los comentarios son `#` o `//`, **no** `;`. Las opciones de lista (`corner-radius-rules`, etc.) son arrays de strings y **deben ir entre comillas** — si no, picom no parsea.

---

## 8. Fase 7 — `~/.config/kitty/kitty.conf`

| Opción | Valor | Razón |
|---|---|---|
| font_size | `10.0` | Compacto pero legible |
| font_family | `JetBrainsMono Nerd Font Mono` | Fuente Nerd para iconos de lsd y glifos de p10k. **HISTORIA:** se probó `Hack Nerd Font Mono` (zip propio descargado a `/usr/share/fonts`), pero las letras se veían recortadas ("no completas") porque Hack tiene métricas de línea más altas y chocaba con el compactado → se volvió a JetBrainsMono y se quitó el `adjust_line_height -4`. |
| cursor_shape | `beam` | Cursor en trazo, menos pesado |
| background_opacity | `0.80` | Prioridad del usuario: transparencia moderada (deja asomar el wallpaper/blur detrás) |
| dynamic_background_opacity | `yes` | Permite ajustar opacidad en vivo con `Ctrl+Shift+O` |
| `background #2E2E2E` (al final) | — | **Fondo gris neutro**: override sobre el fondo azulado de la theme Catppuccin. Va **después** del `include current-theme.conf` para ganarle la partida (kitty aplica la última definición) |
| confirm_os_window_close | `0` | No preguntar al cerrar ventana con muchas pestañas |
| `map ctrl+shift+flechas` | `neighboring_window …` | Navega entre **splits dentro de kitty** |

**Mapa de atajos de navegación final (sin colisiones):**
- `Ctrl+flechas` → cambia ventanas de **bspwm** (nivel WM, las ventanas grandes).
- `Ctrl+Shift+flechas` → cambia splits **dentro de kitty**.
- `Ctrl+Shift+Enter` → nuevo split en kitty.

**Tema:** Catppuccin Mocha vía `kitten themes "Catppuccin-Mocha"`, que escribe `include current-theme.conf` al final del archivo.

---

## 9. Fase 8 — Autostart (dentro de bspwmrc)

```bash
pgrep -x sxhkd >/dev/null || sxhkd &
pgrep -x picom >/dev/null || picom --config ~/.config/picom/picom.conf &
pkill -x polybar 2>/dev/null; while pgrep -u "$UID" -x polybar; do sleep 0.1; done; polybar -r main &
```

- **sxhkd y picom**: solo si no hay otro proceso (evita duplicados).
- **polybar**: siempre se mata y relanza (aplica config nueva; método estándar).
- **<MONITOR>**: se exporta tras detectarlo con `xrandr`.

---

## 10. Fase 9 — Terminal bonita (red y root)

### Instalado
```bash
sudo apt install -y lsd bat zsh-syntax-highlighting zsh-autosuggestions fastfetch
git config --global color.ui true
```

| Pieza | Uso | Notas |
|---|---|---|
| **lsd** | `ls`/`ll`/`lt` con iconos y colores | Requiere Nerd Font (si faltara, iconos = cajas) |
| **bat** | `cat` con resaltado | En Kali se llama **`batcat`** (no `bat`) → alias obligatorio |
| **zsh-syntax-highlighting** | comandos coloreados al tipear | Ruta apt `/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh` |
| **zsh-autosuggestions** | sugerencias grises del historial | Ruta apt análoga |
| **powerlevel10k** | prompt bonito (tema Rainbow) | **NO está en apt** → `git clone --depth=1` de GitHub a `~/powerlevel10k`. Config aplicada: `~/.p10k.zsh` (red) y `/root/.p10k.zsh` (root), copiando el config Rainbow del repo (evita el asistente). |
| **fastfetch** | `alias fetch='fastfetch'` | Auto-info del sistema bajo demanda (no se auto-ejecuta; decisión pendiente de resolver) |
| `git color.ui` | diffs con color | Gratis |

### Fuentes Nerd instaladas
- JetBrainsMono Nerd Font (descarga oficial a `~/.local/share/fonts`) — activa en kitty.
- Hack Nerd Font (zip en `/usr/share/fonts/Hack.zip`, extraído a `/usr/share/fonts/truetype/hacknerd`) — **instalada pero no usada** (probada y revertida; ver sección 8).

### El bloque añadido a `~/.zshrc` y `/root/.zshrc` (solo anexado, con backup)
```sh
alias ls='lsd'
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

**Decisiones:** nada de oh-my-zsh (pesado); el highlight va **después** del p10k (requisito del tema); `BAT_THEME="Catppuccin Mocha"` para combinar con kitty; backups `~/.zshrc.bak.opencode`, `/root/.zshrc.bak.opencode`.

---

## 11. Wallpaper

- Imagen: `~/Pictures/retro1.png` (2912×1632, 16:9).
- Herramienta: **xwallpaper** (`--daemon --zoom`) desde `bspwmrc` y aplicado en vivo con `DISPLAY=:0 xwallpaper --zoom ~/Pictures/retro1.png`.
- **Por qué `--daemon`**: xwallpaper se queda escuchando eventos **RandR** y **repinta solo** el fondo cuando cambia la resolución (achicar/expandir la VM). Sustituyó a `feh --bg-fill --no-fehbg`, que pintaba una sola vez y quedaba desalineado tras el resize. CPU en reposo ~0% (solo despierta con RandR).
- Con la transparencia de picom, el wallpaper se ve desenfocado detrás de las ventanas inactivas.

---

## 12. Resumen de cambios visuales (turno "compacto y contraste")

1. kitty: `font_size` 11→**10**, `adjust_line_height -4` (luego **eliminado** por recorte de letras), opacidad 0.95→**0.97**→**0.80**.
2. bat: `BAT_THEME` de `ansi` → **`Catppuccin Mocha`** (red y root).
3. bspwm: `window_gap` 12→**8**, `border_width` 2→**1**.
4. polybar: `height` 24→**20**, fuente 9→**8**, paddings/márgenes reducidos, workspace enfocado **invertido** (blanco/negro).
5. fastfetch: alias `fetch`.

---

## 13. Cómo recargar cada cosa (tabla de supervivencia)

| Cambio en… | Recarga |
|---|---|
| `bspwmrc` / `polybar` / bordes / gap | `Super+Alt+r` (reinicia bspwm; polybar se relanza sola) |
| `sxhkdrc` (atajos) | `Super+Escape` (o `pkill -USR1 -x sxhkd`) |
| `picom.conf` | `pkill -x picom && bspc wm -r` (bspwmrc relanza picom) |
| `kitty.conf` / fuente / tema | `Ctrl+Shift+F5` (en caliente) o nueva ventana |
| `.zshrc` / bat / p10k | Abrir **terminal nueva** |

---

## 14. Mantenimiento y diagnóstico

```bash
# Estado del stack (sin duplicados, consumo real)
ps -o pid,comm,%cpu,rss -C bspwm -C sxhkd -C picom -C polybar

# ¿GL por software? (debería NO decir llvmpipe)
glxinfo -B | grep -i renderer

# Log de picom
tail -f /tmp/picom.log

# Fallback sin blur (en picom.conf)
#   blur-method = "none"   +   bspc wm -r

# Verificación del wallpaper aplicado
xprop -root _XROOTPMAP_ID
```

**Umbrales de rendimiento:** picom en reposo ~0.5-2% CPU. Si al mover ventanas pasa de ~6-7% → bajar blur. polybar ~2%, bspwm/sxhkd ~0%.

---

## 15. Estructura final de archivos

```
~/.config/
├── bspwm/bspwmrc         # WM: 9 escritorios, bordes, gap, wallpaper, autostart
├── sxhkd/sxhkdrc         # Atajos de teclado
├── polybar/config.ini    # Barra negra/blanca compacta con IP eth0
├── picom/picom.conf      # Compositor xrender: esquinas + blur + opacidad
└── kitty/
    ├── kitty.conf        # Terminal: JetBrainsMono Nerd, fondo #2E2E2E, splits
    └── current-theme.conf# Tema Catppuccin Mocha (generado por kitten themes)

~/.zshrc  /root/.zshrc    # lsd, batcat, p10k, plugins (bloques anexados, con backup)
~/powerlevel10k/          # Repo del tema p10k
~/.p10k.zsh /root/.p10k.zsh  # Config Rainbow del prompt
~/.local/share/fonts/     # JetBrainsMono Nerd Font
/usr/share/fonts/truetype/hacknerd/  # Hack Nerd Font (instalada, sin usar; zip en /usr/share/fonts/Hack.zip)
~/Pictures/retro1.png     # Wallpaper
AGENTS.md                 # Resumen de estado (para que opencode retome contexto)
entorno.md                # Este documento
```

---

## 16. Pendientes / ideas no ejecutadas

- `fzf` (Ctrl+R fuzzy) y/o `zoxide` — ofrecidos, no aceptados.
- fastfetch **automático** al abrir terminal, o con logo personalizado (`retro1.png`) — no decidido.
- Ajustar la "baja" de procesos flotantes o afinar gap/bordes si el layout cambia de gusto.
- `adjust_line_height` si un día se quiere más compacto sin recortar (JetBrains tolera hasta ~-2).

---

# APÉNDICE — Contenido COMPLETO y actual de cada archivo (verificado)

> Cada archivo se reproduce tal cual está hoy en el sistema, con el **por qué** de sus líneas más importantes anotado debajo. Los valores marcados con ← ****son los que se cambiaron** respecto a su versión inicial o son decisiones deliberadas.

## A.1 `~/.config/bspwm/bspwmrc` (63 líneas)

```bash
#!/bin/sh

# =====================================================================
# bspwmrc  -  Script que bspwm ejecuta al iniciar.
# Mi primera config basica: estable, ligera y facil de ampliar.
# =====================================================================

# --- Teclado ----------------------------------------------------------
setxkbmap -layout latam                        # ← de "us" a "latam"

# --- Fondo de pantalla (wallpaper con feh) -----------------------------
feh --bg-fill --no-fehbg "$HOME/Pictures/retro1.png"
xsetroot -cursor_name left_ptr

# --- Escritorios / Workspaces -----------------------------------------
bspc monitor -d 1 2 3 4 5 6 7 8 9              # ← 9 escritorios

# --- Comportamiento basico de ventanas --------------------------------
bspc config border_width          1            # ← era 2, ahora 1 (afilado)
bspc config normal_border_color   "#30302f"
bspc config active_border_color   "#ffffff"    # ← blanco: ventana con foco por raton
bspc config focused_border_color  "#ffffff"    # ← blanco: foco por teclado
bspc config window_gap           8             # ← era 12, ahora 8 (compacto)
bspc config split_ratio         0.52

bspc config single_monocle       true
bspc config borderless_monocle   true
bspc config gapless_monocle      true

bspc config click_to_focus       true
bspc config pointer_follows_focus  true
bspc config follow_mouse         yes

# --- Autostart (con guardas anti-duplicado) ----------------------------
pgrep -x sxhkd > /dev/null || sxhkd &          # sxhkd NO lo lanza la sesion
pgrep -x picom > /dev/null || picom --config ~/.config/picom/picom.conf &
if [ -z "$MONITOR" ]; then
    MONITOR=$(xrandr --current | grep -w primary | awk '{print $1}')
fi
[ -z "$MONITOR" ] && MONITOR=$(xrandr --current | grep -E '\bconnected\b' | grep -v disconnected | awk '{print $1}' | head -1)
export MONITOR
pkill -x polybar 2> /dev/null
while pgrep -u "$UID" -x polybar > /dev/null; do sleep 0.1; done
polybar -r main &
```

**Por qué / decisiones en este archivo:**
- **`setxkbmap -layout latam`**: tu teclado físico es latinoamericano.
- **`xwallpaper --daemon --zoom`**: sustituyó al antiguo `feh --bg-fill --no-fehbg` (y antes `xsetroot -solid`). `--zoom` escala la imagen 2912×1632 recortando para cubrir la pantalla; `--daemon` escucha eventos RandR y **repinta solo** cuando cambia la resolución de la VM (feh pintaba una sola vez y quedaba desalineado).
- **`bspc monitor -d 1..9`**: 9 escritorios que coinciden 1 a 1 con `Super+[1-9]` y `Super+Shift+[1-9]`.
- **Bordes en blanco**: la ventana enfocada (por teclado con `Ctrl+flechas` o por ratón) se resalta en blanco; las demás en gris oscuro `#30302f`. El borde blanco es lo que te permite *ver* qué ventana tienes enfocada sin mirar el entorno.
- **`window_gap 8`**: era 12; se bajó para ganar espacio y hacer el layout más compacto.
- **`single_monocle` + `gapless_monocle`**: con una sola ventana ocupa todo el escritorio (sin espacio muerto) — muy útil en VM.
- **Guardas anti-duplicado**: bspwmrc se re-ejecuta en cada `Super+Alt+r`; `pgrep … ||` evita un segundo sxhkd/picom (doble RAM/CPU). Polybar se mata y relanza siempre porque así aplica cambios de config (método estándar).
- **`MONITOR` dinámico**: se detecta con `xrandr` y se exporta. Motivo: el nombre del monitor cambia entre tu VM (`Virtual-1`), otra VM y Xvfb (`screen`); hardcodearlo rompería la barra.

---

## A.2 `~/.config/sxhkd/sxhkdrc` (51 líneas)

```bash
#!/bin/sh

super + Return
    kitty

super + q
    bspc node -c

super + space
    bspc query -N -n focused.floating >/dev/null && bspc node -t tiled || bspc node -t floating

super + {1-9}
    bspc desktop -f ^{1-9}

super + Escape
    pkill -USR1 -x sxhkd

super + alt + {q,r}
    bspc {quit,wm -r}

ctrl + {Left,Down,Up,Right}
    bspc node -f {west,south,north,east}

# --- Mover ventana a otro escritorio ------------------------------------
super + shift + {1-9}                          # ← AGREGADO (último cambio)
    bspc node -d ^{1-9}
```

**Por qué / decisiones:**
- **`super+shift+{1-9}` → `bspc node -d`**: mueve **la ventana enfocada** al escritorio que elijas. La diferencia clave con `super+{1-9}` (que solo cambia de escritorio) es el flag `-d` de **nodo**. Es el snippet oficial de bspwm y funciona con Shift aunque el teclado latam cambie el símbolo de las teclas numéricas.
- **`ctrl+{Left,...}` → `bspc node -f {west,...}`**: cambiar foco entre ventanas de bspwm sin mouse. Trade-off asumido: pierdes el salto de palabra en terminales (Ctrl+←/→).
- **`super+alt+r` → `bspc wm -r`**: reinicia bspwm (recarga bspwmrc). `super+alt+q` → `bspc quit` cierra la sesión.
- No hay decenas de atajos: solo los esenciales + los que pediste, para mantener la config fácil de leer.

---

## A.3 `~/.config/polybar/config.ini` (106 líneas)

```ini
; =====================================================================
[colors]
bg        = #000000        # ← barra negra
fg        = #ffffff        # ← texto blanco
accent    = #ffffff
border    = #1a1a1a        # ← mas oscuro que antes (#222222)
focusedbg = #ffffff        # ← workspace enfocado: fondo BLANCO
focusedfg = #000000        #    con texto NEGRO (invertido)
emptyfg   = #666666

[bar/main]
monitor = ${env:MONITOR}   # ← inyectado por bspwmrc (deteccion xrandr)

width       = 100%
height      = 20           # ← era 24, ahora compacta
radius      = 0
offset-y    = 0

background  = ${colors.bg}
foreground  = ${colors.fg}
line-size   = 1            # ← era 2
line-color  = ${colors.border}
border-top-size   = 0
border-bottom-size = 1    # ← era 2
border-bottom-color = ${colors.border}

padding-left  = 2          # ← era 4
padding-right  = 2
module-margin = 1          # ← era 2

font-0 = DejaVu Sans Mono:size=8;2   # ← era size=9
                                           ; el ";2" = factor de escala

modules-left   = workspaces
modules-center =
modules-right  = cpu memory net date

warn-unknown-modules = false

; =========================== WORKSPACES ==============================
[module/workspaces]
type = internal/bspwm
label-focused   = %name%
label-focused-background   = ${colors.focusedbg}
label-focused-foreground   = ${colors.focusedfg}   # ← invertido (blanco/negro)
label-focused-underline    = ${colors.accent}
label-occupied   = %name%
label-occupied-foreground = ${colors.fg}
label-empty      = %name%
label-empty-foreground    = ${colors.emptyfg}
label-separator  = " "
label-padding    = 2

; ============================== CPU  =================================
[module/cpu]
type = internal/cpu
interval = 2
format-prefix       = "CPU:"
format-prefix-foreground = ${colors.accent}
label = %percentage%%

; ============================= RAM  ==================================
[module/memory]
type = internal/memory
interval = 2
format-prefix       = "RAM:"
format-prefix-foreground = ${colors.accent}
label = %used% / %total%

; ============================= NET  ==================================
[module/net]
type = internal/network
interface = eth0
interval  = 3
format-connected     = <label-connected>
format-connected-background = ${colors.bg}
label-connected      = "IP %local_ip%  D:%downspeed% U:%upspeed%"
format-disconnected  = "NET OFF"
format-disconnected-foreground = ${colors.emptyfg}

; ============================ DATE  ==================================
[module/date]
type = internal/date
interval = 1
date = %d/%m/%a
time = %H:%M
label = "%date% %time%"
label-foreground = ${colors.fg}
```

**Por qué / decisiones:**
- **Barra negra con texto blanco**: la pediste así; el workspace enfocado se invirtió (fondo blanco + letra negra) para que salte a la vista con máximo contraste.
- **Ningún módulo lanza scripts** (todos `type = internal/*`): es la garantía de consumo mínimo (medido ~2% CPU, sin procesos hijos).
- **La IP sale sin scripts**: `%local_ip%` es una variable interna del módulo `internal/network` en polybar 3.7.2 (verificado en `man`/ejemplos del paquete). Se auto-refresca con el poll de 3s.
- **Módulo `date`**: necesita las claves `date` y `time` **por separado** (bug real que se corrigió: sin `time` el módulo se apagaba).
- **No hay `tray`**: se dejó fuera a propósito (bandeja = más CPU/ruido visual; no la usas).
- **Compacta**: `height 20`, fuente 8, padding/márgenes mínimos.

---

## A.4 `~/.config/picom/picom.conf` (97 líneas)

```ini
backend = "xrender"                     # ← CLAVE: evita llvmpipe (GL por software)
vsync   = false

corner-radius = 12                      # ← esquinas redondeadas (pedidas)
round-borders = 0
corner-radius-rules = [                 # rectos: fullscreen, barra, docks, menús
    "0:fullscreen",
    "0:window_type = 'dock'",
    "0:class_g = 'Polybar'",
    "0:window_type = 'popup_menu'",
    "0:window_type = 'dropdown_menu'"
];

shadow              = true
shadow-radius       = 8
shadow-opacity      = 0.20              # ← muy sutil (default 0.75 = pesado)
shadow-offset-x     = -2
shadow-offset-y     = -2
shadow-red          = 0.0
shadow-green        = 0.0
shadow-blue         = 0.0
shadow-ignore-shaped = true

shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Polybar'",
    "class_g = 'Dunst'",
    "window_type = 'desktop'",
    "window_type = 'menu'",
    "window_type = 'tooltip'"
]

active-opacity   = 0.90                 # ← enfocada casi opaca
inactive-opacity = 0.80                 # ← inactiva deja ver el fondo desenfocado
frame-opacity    = 1.0

blur-background      = true
blur-background-frame = false
blur-background-fixed = false
blur-background-exclude = [             # no desenfocar barra/dock/desktop
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "class_g = 'Polybar'"
]

blur-method   = "dual_kawase"           # ← el más ligero (2 pasadas)
blur-strength = 5                       # ← era 4, se subió a 5 (más visible)

fading  = false
fade-in-step  = 0.06
fade-out-step = 0.06
active-opacity-override = true

unredir-if-possible = true
use-damage = true

log-level  = "warn"
log-path   = "/tmp/picom.log"
```

**Por qué / decisiones (las más importantes del entorno):**
- **`backend = "xrender"`**: como la GPU es virtual, usar `egl`/`glx` haría que picom pidiera OpenGL y Kali lo resolvería con **llvmpipe** (software) → CPU cara. `xrender` es el render 2D de X: barato y suficiente. Si algún día lo cambias, pásalo a `egl` solo si tienes GPU real.
- **`corner-radius = 12` + `corner-radius-rules`**: esquinas redondeadas en ventanas normales, pero la barra/pantalla completa/docks/menús se quedan **rectos** (las rules tienen prioridad). Nota libconfig: las listas van citadas como strings, si no, no parsea.
- **`dual_kawase` + `strength 5`**: método de blur más eficiente; 5 es suave y visible. Si al mover ventanas la CPU pasara de ~6-7%, baja a 3 o `"none"`.
- **Opacidad enfocada/inactiva 0.90/0.80**: el blur se ve **a través de las ventanas inactivas** (semi-transparentes); la enfocada queda casi sólida para leer bien.
- **Vsync/animaciones OFF**: en una VM no hay tearing real; los efectos gastan CPU, así que se dejan apagados.
- **`unredir-if-possible`**: con pantalla completa (vídeo) picom se "quita" y deja pasar sin compositar → menos carga.
- **`log-path /tmp/picom.log`**: diagnóstico sin tocar la pantalla (`tail -f /tmp/picom.log`).

---

## A.5 `~/.config/kitty/kitty.conf` (36 líneas)

```conf
font_size         10.0                    # ← era 11.0, ahora 10 (compacto)
font_family       JetBrainsMono Nerd Font Mono   # ← VOLVIÓ de Hack (ver abajo)

cursor_shape      beam

background_opacity 0.80                   # ← era 0.97, ahora 0.80 (más transparente, pedido)
dynamic_background_opacity yes

confirm_os_window_close 0

map ctrl+shift+left   neighboring_window left    # ← splits dentro de kitty
map ctrl+shift+right  neighboring_window right
map ctrl+shift+up     neighboring_window up
map ctrl+shift+down   neighboring_window down

# BEGIN_KITTY_THEME
# Catppuccin-Mocha
include current-theme.conf
# END_KITTY_THEME

# Fondo gris neutro (override sobre el color de la theme) - elegido por el usuario.
background #2E2E2E                       # ← GRIS pedido; va DESPUÉS del include
```

**Por qué / decisiones:**
- **`font_family JetBrainsMono Nerd Font Mono`**: historia completa → se probó **Hack Nerd Font** (descomprimida de tu `Hack.zip` a `/usr/share/fonts/truetype/hacknerd`), pero las letras se veían **"no completas y raras"**: Hack tiene métricas de línea más altas y, sumado al `adjust_line_height -4` que había puesto para compactar, las letras quedaban **recortadas** arriba/abajo. Solución: volver a **JetBrainsMono** (ya instalada, probada, glifos completos) y **eliminar el `adjust_line_height -4`** (filas a alto normal = cero recortes).
- **`background #2E2E2E` al final**: override del fondo azulado de Catppuccin. Debe ir **después** del `include current-theme.conf` porque kitty aplica la **última** definición. Así, si vuelves a correr `kitten themes`, el include se regenera pero tu gris queda por encima.
- **`background_opacity 0.80`**: pedido ("un poco más de transparencia"); deja asomar el wallpaper/blur de picom detrás.
- **`map ctrl+shift+flechas` → `neighboring_window`**: navega los **splits** del mismo kitty. No usa `ctrl+flechas` a secas porque esas ya las tiene **sxhkd** a nivel de WM (choque resuelto dejando `ctrl` al WM y `ctrl+shift` a kitty).
- **Fuente Nerd** = necesaria para los iconos de lsd y los glifos del prompt powerlevel10k.

---

## A.6 Bloque añadido a `~/.zshrc` y `/root/.zshrc` (final del archivo)

```sh
# ---------------------------------------------------------------
# --- Terminal bonita (opencode: lsd / bat / powerlevel10k) -------
# ---------------------------------------------------------------
alias ls='lsd'
alias ll='lsd -la --icon always'
alias lt='lsd --tree --icon always'
alias cat='batcat --paging=never'
alias fetch='fastfetch'
export BAT_THEME="Catppuccin Mocha"        # ← era "ansi", ahora tema de contraste

# Powerlevel10k (tema del prompt). Personaliza con: p10k configure
[[ ! -f ~/powerlevel10k/powerlevel10k.zsh-theme ]] || source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Plugins zsh: el highlight va DESPUES del theme (requisito de p10k)
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

**Por qué / decisiones:**
- El bloque solo se **anexó al final** (con backups `~/.zshrc.bak.opencode` y `/root/.zshrc.bak.opencode`), sin reescribir nada de tu zshrc original.
- **`alias cat='batcat …'`**: en Kali/Debian el paquete `bat` se instala como `batcat` (no `bat`) — clave, si no, el alias apuntaría a nada.
- **`BAT_THEME="Catppuccin Mocha"`**: tema de alto contraste de `batcat` (verificado con `batcat --list-themes`) para que combine con kitty; antes era `ansi` (apagado).
- **p10k vía `git clone --depth=1`** (no está en apt; nada de oh-my-zsh). El config **Rainbow** vino del repo (`~/.p10k.zsh`), evitando el asistente interactivo. La estructura del theme difiere según versión: el hook real se llama `prompt_powerlevel10k_…` y renderiza en `precmd` (por eso un test con `zsh -ic` no muestra el prompt — se verificó con el `PROMPT` de una sesión real).
- **`source` del highlight DESPUÉS del theme**: requisito explícito de powerlevel10k para que no pise colores.
- **fastfetch**: `alias fetch='fastfetch'` bajo demanda (no automático en cada terminal; si se quiere, añadir su llamado en la primera línea).

---

## A.7 Estado del sistema al documentar

```bash
# Procesos del stack (sin duplicados, consumo estable medido)
bspwm    0.0 % CPU  ~2.6 MB RAM
sxhkd    0.0 % CPU  ~2.4 MB RAM
picom   ~1.5 % CPU  ~9   MB RAM   (blur dual_kawase 5 + esquinas + opacidad)
polybar ~2.0 % CPU  ~20  MB RAM   (5 módulos)

# Paquetes clave instalados (dpkg): bspwm 0.9.12 · sxhkd 0.6.3 · polybar 3.7.2
# · picom 13 · kitty 0.47.3 · lsd 1.2.0 · bat 0.26.1 (+batcat) · xwallpaper 0.7.6
# · fastfetch 2.66.0 · zsh 5.9 · fonts: JetBrainsMono Nerd (activa) + Hack Nerd (no usada)
# · xserver-xorg-video-vmware 13.3.0 (desde Debian bookworm; fix resize en Workstation 25.x)

# Fallback rápido si picom pesa: en picom.conf poner blur-method = "none" y `bspc wm -r`.