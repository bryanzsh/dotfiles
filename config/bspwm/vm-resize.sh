#!/bin/sh

# =====================================================================
# vm-resize.sh  -  Reencaja el desktop a la resolucion de la ventana VM
# Con un WM tiling (bspwm) las VMware Tools solo marcan el nuevo tamano
# como "preferred" sin aplicarlo. `xrandr --auto` activa ese modo, RandR
# emite monitor_geometry y bspwm re-dibuja los tiles solo (sin reiniciar).
# Polybar se relanza aparte para ajustar su ancho al nuevo resolucion.
# =====================================================================

xrandr --auto

if [ -z "$MONITOR" ]; then
    MONITOR=$(xrandr --current | grep -w primary | awk '{print $1}')
fi
[ -z "$MONITOR" ] && MONITOR=$(xrandr --current | grep -E '\bconnected\b' | grep -v disconnected | awk '{print $1}' | head -1)
export MONITOR

pkill -x polybar 2> /dev/null
while pgrep -u "$(id -u)" -x polybar > /dev/null; do sleep 0.1; done
nohup polybar -r main > /dev/null 2>&1 &