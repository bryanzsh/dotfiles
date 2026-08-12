# vmtools — Resize automático de la VM (VMware Tools + Xorg + composición)

> Documento específico del stack de **resize de la resolución de la VM** (Kali + bspwm).
> Si querés la bitácora completa del entorno, mirá `entorno.md`. Este archivo solo documenta
> **cómo funciona y cómo se configura el cambio de resolución**, tal como quedó resuelto el 2026-08-12.

---

## 1. Resumen

- **Sistema:** Kali GNU/Linux Rolling 2026.3 · VM en VMware Workstation 25.x (GPU virtual VMware SVGA II).
- **WM:** bspwm · Compositor: picom (xrender) · Barra: polybar · Fondo: `xwallpaper --daemon`.
- **Filosofía (estilo s4vitar):** **cero scripts**. El resize se resuelve con:
  1. Driver X correcto → **`vmware_drv.so`** (los eventos de resize/EDID llegan a tiempo).
  2. Xorg maneja el modo → emite `monitor_geometry` → **bspwm re-tila solo**.
  3. **`xwallpaper --daemon`** escucha RandR y repinta el fondo solo.
  4. Loop inline en bspwmrc relanza **polybar** sola con el ancho nuevo.

**Resultado:** arrastrás el borde de la ventana de la VM (o cambiás la resolución en VMware) y todo se reacomoda solo, sin ejecutar nada.

---

## 2. Paquetes instalados (requisitos)

| Paquete | Versión | Rol |
|---|---|---|
| `open-vm-tools` | 2:13.0.10 | Agente invitado (clipboard, drag&drop, registros, resize host→guest) |
| `open-vm-tools-desktop` | 2:13.0.10 | Agente GUI `vmware-user` (portapapeles + resize en sesión gráfica) |
| `xwallpaper` | 0.7.6 | Fondo que repinta solo ante RandR (`--daemon`) |
| `xserver-xorg-video-vmware` | 1:13.3.0 | **Driver X de VMware** (la pieza crítica del resize) |

> ⚠️ El driver **no** viene por defecto en Kali: falla a `modesetting` (ver §6). Se instaló desde Debian bookworm.

**Instalación del driver desde bookworm** (una sola vez):
```sh
echo "deb http://deb.debian.org/debian bookworm main contrib non-free" | sudo tee /etc/apt/sources.list.d/tmp-bookworm.list
sudo apt update
sudo apt install -y xserver-xorg-video-vmware
sudo rm /etc/apt/sources.list.d/tmp-bookworm.list && sudo apt update
```
Tras instalarlo, **reiniciar lightdm** (`systemctl restart lightdm` o reboot) para que Xorg lo cargue.

---

## 3. Servicio open-vm-tools

Debe estar **enabled + active**:

```sh
systemctl is-enabled open-vm-tools.service   # enabled
systemctl is-active  open-vm-tools.service   # active
systemctl status open-vm-tools.service       # detalle
```

Aporta el daemon de servicios del hipervisor (heartbeat, ejecución de comandos del host, init-guestos, etc.).

---

## 4. Agente GUI `vmware-user`

Dos binarios:

- `/usr/bin/vmware-user` → **symlink** a `vmware-user-suid-wrapper`.
- `/usr/bin/vmware-user-suid-wrapper` → binario **setuid root** (`-rwsr-xr-x`). Es el que corre el agente con los permisos que necesita tocar portapapeles/resolución.

En un DE con gestor de sesión el agente se auto-lanza; **con bspwm vía lightdm no** → se arranca a mano en `bspwmrc` con guarda anti-duplicado (no es un script aparte, es una línea de autostart):

```sh
# VMware Tools GUI: portapapeles + drag&drop + resize host<->guest.
pgrep -f vmware-user > /dev/null || /usr/bin/vmware-user-suid-wrapper > /dev/null 2>&1 &
```

Verificación:
```sh
pgrep -f vmware-user       # PID vivo
```

---

## 5. Driver X correcto: `vmware_drv.so`

Este es **el núcleo del fix**. Con el driver cargado, Xorg maneja él mismo los modos de resolución y propaga el cambio a los clientes (bspwm, xwallpaper, polybar) de forma fiable.

Comprobar en `/var/log/Xorg.0.log`:
```
(==) Matched vmware as autoconfigured driver 0
(II) Loading /usr/lib/xorg/modules/drivers/vmware_drv.so
```

Si en el log dice `Failed to load module "vmware"` y cae a `modesetting`, hay interpretar el bug (ver §6).

---

## 6. Por qué `modesetting` rompía el resize (Kali BTS #9496)

- Kali dejó de compilar `xserver-xorg-video-vmware` → X caía al fallback `modesetting`.
- Con `modesetting` + **VMware Workstation 25.x** los **eventos de resize/EDID llegan tarde o se pierden**: la resolución cambiaba sola, a destiempo o con resolución incorrecta.
- Con `vmware_drv.so` Xorg procesa los modos propios del SVGA II y **emite `monitor_geometry` de bspwm a tiempo** → el WM re-tila solo.

Síntoma típico del bug: redimensionás la VM y el contenido queda a una resolución vieja, escalado o el clic no coordina (offset).

---

## 7. Cadena completa del resize (cómo funcionan las piezas juntas)

```
Arrastrás el borde de la VM (o View→resolution)
        │
        ▼
VMware Workstation   → resize de la ventana (SVGA II / EDID)
        │
        ▼
Xorg (vmware_drv.so)  → resuelve el nuevo modo "preferred" → evento RandR
        │
        ├──► bspc monitor_geometry  → bspwm RE-TILA las ventanas solo
        ├──► xwallpaper --daemon    → REPINTA el fondo solo
        └──► loop polybar (bspwmrc) → RELANZA polybar con el ancho nuevo
        ▼
Resolución acomodada en ~instantáneo, sin script ni atajo
```

Las tres piezas reactivas viven en **`bspwmrc`**:

```sh
# 1) Fondo ROTATIVO (todas las imagenes de ~/Pictures, cada 60s)
#    xwallpaper "--daemon" sigue RandR y repinta solo ante el resize.
#    Guarda WALLROT en el cmdline -> sin duplicados en Super+Alt+r.
( pgrep -f WALLROT > /dev/null || \
    setsid sh -c 'while true; do
      for img in "$HOME"/Pictures/*; do
        [ -f "$img" ] || continue
        case "$img" in
          *.png|*.jpg|*.jpeg|*.PNG|*.JPG|*.JPEG) ;;
          *) continue ;;
        esac
        pkill -x xwallpaper 2> /dev/null
        while pgrep -u "$(id -u)" -x xwallpaper > /dev/null; do sleep 0.1; done
        xwallpaper --daemon --zoom "$img" &
        sleep 60
      done
    done # WALLROT' > /dev/null 2>&1 ) &

# 2) Polybar + resize: se relanza sola ante monitor_geometry
( pgrep -f 'bspc subscribe monitor_geometry' > /dev/null || \
    bspc subscribe monitor_geometry | while read -r _; do
      pkill -x polybar 2> /dev/null
      while pgrep -u "$(id -u)" -x polybar > /dev/null; do sleep 0.1; done
      polybar -r main &
    done ) &

# 3) Agente vmware-user (portapapeles + resize host<->guest)
pgrep -f vmware-user > /dev/null || /usr/bin/vmware-user-suid-wrapper > /dev/null 2>&1 &
```

> Nota sobre `--zoom`: equivale al `--bg-fill` de feh (cubre la pantalla recortando según aspect ratio). `--daemon` = se queda escuchando RandR, CPU en reposo ~0 %; en cada ciclo el pkill + relanzamiento pinta la siguiente imagen de `~/Pictures` (glob re-evaluado: toma imágenes nuevas sin recargar).
>
> Nota polybar: su `width=%` se calcula al arrancar; por eso no alcanza con el evento — hay que **relanzarla**. El loop lo hace en bspwmrc, con guarda `pgrep` para no duplicarse en `Super+Alt+r`.

---

## 8. Cómo resizear la VM (uso diario)

| Cómo | Qué pasa |
|---|---|
| Arrastrar un borde/esquina de la ventana de la VM | VMware cambia el modo → cadena del §7 → todo se reacomoda |
| Menú `View` → `Autosize` → *Autofit Guest* | Opción de VMware que ajusta el guest al cambio de tamaño |
| Puerto serie de resolución (si puntual) | `xrandr` sigue disponible para cambiar resolución a mano |

Para forzar una resolución puntual a mano (sin que el host la dicte):
```sh
xrandr --output Virtual1 --mode 1920x1080
```

---

## 9. Verificación rápida (todo OK)

```sh
systemctl is-active open-vm-tools.service                # active
pgrep -f vmware-user                                     # PID vivo
grep -m1 'Matched vmware' /var/log/Xorg.0.log            # driver cargado
xrandr --current | grep Virtual1                         # resolución actual
pgrep -f 'bspc subscribe monitor_geometry'               # loop de polybar vivo
pgrep -x polybar ; pgrep -x xwallpaper                   # barra + fondo vivos
pgrep -f WALLROT                                         # loop rotativo de fondo vivo
```

---

## 11. Wallpaper rotativo: cómo configurarlo

El fondo de pantalla **rota cada 60 s** por todas las imágenes de `~/Pictures`
(extensiones `png/jpg/jpeg`; el glob `~/Pictures/*` + filtro `case` descarta los
`.Zone.Identifier` y otros archivos no-imagen).

| Acción | Cómo |
|---|---|
| **Añadir una imagen** | Copiarla a `~/Pictures/` — el loop la toma en la próxima vuelta (glob re-evaluado). |
| **Cambiar el intervalo** | Editar el `sleep 60` del loop en `bspwmrc` y recargar (`Super+Alt+r`). |
| **Solo una imagen fija** | Quitar el loop rotativo del `bspwmrc` y volver a `xwallpaper --daemon --zoom "$HOME/Pictures/IMAGEN"` |
| **Ver la imagen actual** | `pgrep -a xwallpaper` muestra con qué archivo está pintando el daemon. |

**Por qué funciona con el resize:** aunque el loop mata y relanza el daemon cada
minuto, ese daemon siempre se lanza con `--daemon` = escucha RandR y repinta solo
si cambia la resolución en ese minuto; en el siguiente ciclo relanza con la misma
fidelidad. El resize y la rotación conviven sin scripts.

---

## 12. Troubleshooting

| Problema | Causa probable | Solución |
|---|---|---|
| Al redimensionar queda resolución vieja/escalada | X org cargó `modesetting` (no `vmware`) | Reinstalar driver (§2) y reiniciar lightdm |
| `Xorg.0.log` dice `Failed to load module "vmware"` | Kali no trae el driver | Instalarlo desde bookworm (§2) |
| `vmware-user` no corre | Falta `open-vm-tools-desktop` o el servicio | `apt install open-vm-tools-desktop` + `systemctl start open-vm-tools` |
| Polybar no ajusta el ancho tras resize | Loop de `monitor_geometry` no vivo | Revisar §9 (`pgrep -f 'bspc subscribe monitor_geometry'`) o recargar `bspc wm -r` |
| El fondo queda desalineado | Faltó `xwallpaper --daemon` (repintó una sola vez) | Reiniciar bspwm (`Super+Alt+r`) |

---

## 13. Archivos clave

| Archivo | Pieza | Líneas relevantes |
|---|---|---|
| `~/.config/bspwm/bspwmrc` | Autostart del stack (fondo, polybar-loop, agente) | xwallpaper / loop `monitor_geometry` / `vmware-user-suid-wrapper` |
| `/usr/lib/xorg/modules/drivers/vmware_drv.so` | Driver X VMware | — |
| `/var/log/Xorg.0.log` | Diagnóstico del driver | líneas `vmware` / `modesetting` |

**Recargar tras tocar config:** `Super+Alt+r` (reinicia bspwm + pico; relanza polybar y aplica el stack).