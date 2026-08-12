#!/bin/bash
# =====================================================================
# install.sh - Instala el entorno completo (bspwm/sxhkd/polybar/picom/
#              kitty/nvim) tal como esta configurado en este repo.
#
# Uso:
#   ./install.sh          # instala para el usuario actual
#   ./install.sh --root   # ademas replica configs en /root
#
# Idempotente: puedes ejecutarlo varias veces sin romper nada
# (cada archivo se respalda como *.bak antes de sobrescribirse).
# =====================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
INSTALL_ROOT=0
[[ "${1:-}" == "--root" ]] && INSTALL_ROOT=1

say()  { printf '\033[1;36m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERR]\033[0m %s\n' "$*"; exit 1; }

need_sudo() {
    if ! sudo -v 2>/dev/null; then
        sudo true || die "sudo requerido"
    fi
}

# ---------------------------------------------------------------------
# 1) Paquetes base (Debian / Kali)
# ---------------------------------------------------------------------
install_packages() {
    say "Actualizando apt e instalando paquetes..."
    need_sudo
    sudo apt-get update -y
    sudo apt-get install -y \
        bspwm sxhkd polybar picom kitty \
        zsh zsh-syntax-highlighting zsh-autosuggestions \
        lsd bat fastfetch feh x11-xserver-utils \
        ripgrep tree-sitter-cli nvim \
        open-vm-tools open-vm-tools-desktop
}

# ---------------------------------------------------------------------
# 2) Fuente JetBrainsMono Nerd Font (~/.local/share/fonts)
# ---------------------------------------------------------------------
install_font() {
    say "Instalando JetBrainsMono Nerd Font (variante no-Mono)..."
    local FONTDIR="$HOME/.local/share/fonts"
    local TMPZIP
    TMPZIP="$(mktemp)"
    mkdir -p "$FONTDIR"
    curl -fL -o "$TMPZIP" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
        || warn "No se pudo descargar la fuente (revisa la URL o hazlo a mano en $FONTDIR)"
    unzip -o -q "$TMPZIP" -d "$FONTDIR" 2>/dev/null || warn "ZIP invalido; ignora si ya tienes la fuente."
    rm -f "$TMPZIP"
    fc-cache -f >/dev/null 2>&1
}

# ---------------------------------------------------------------------
# 3) powerlevel10k (para el prompt zsh)
# ---------------------------------------------------------------------
install_p10k() {
    say "Clonando powerlevel10k en ~/powerlevel10k..."
    if [ ! -d "$HOME/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    else
        warn "~/powerlevel10k ya existe (se mantiene)."
    fi
}

# ---------------------------------------------------------------------
# Copia un archivo con backup (si existe algo previo).
# $1 = origen  $2 = destino
# ---------------------------------------------------------------------
copy_with_backup() {
    if [ -e "$2" ] && ! cmp -s "$1" "$2"; then
        cp -L "$2" "$2.bak"
        warn "Backup de $2 -> $2.bak"
    fi
    install -D -m 600 "$1" "$2"
}

# ---------------------------------------------------------------------
# 4) Configs de aplicaciones en ~/.config
# ---------------------------------------------------------------------
install_configs() {
    say "Copiando configuraciones a ~/.config..."
    local apps=(bspwm sxhkd kitty polybar picom nvim)
    for app in "${apps[@]}"; do
        [ -d "$REPO_DIR/config/$app" ] || continue
        mkdir -p "$CONFIG_DIR/$app"
        cp -a "$REPO_DIR/config/$app/." "$CONFIG_DIR/$app/"
        warn "Config de $app instalada (se sobrescribio la existente)."
    done
    chmod +x "$CONFIG_DIR/bspwm/bspwmrc" "$CONFIG_DIR/bspwm/vm-resize.sh" 2>/dev/null || true
}

# ---------------------------------------------------------------------
# 5) Home dotfiles (.zshrc, .p10k.zsh)
# ---------------------------------------------------------------------
install_home() {
    say "Instalando dotfiles de HOME..."
    [ -f "$REPO_DIR/home/.zshrc" ] && copy_with_backup "$REPO_DIR/home/.zshrc" "$HOME/.zshrc"
    [ -f "$REPO_DIR/home/.p10k.zsh" ] && copy_with_backup "$REPO_DIR/home/.p10k.zsh" "$HOME/.p10k.zsh"
}

# ---------------------------------------------------------------------
# 6) Sesion bspwm en lightdm (si falta el .desktop)
# ---------------------------------------------------------------------
install_session() {
    if [ ! -f /usr/share/xsessions/bspwm.desktop ]; then
        say "Creando /usr/share/xsessions/bspwm.desktop..."
        need_sudo
        sudo tee /usr/share/xsessions/bspwm.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=bspwm
Comment=Binary space partitioning window manager
Exec=bspwm
Type=Application
DesktopNames=bspwm
EOF
    else
        warn "/usr/share/xsessions/bspwm.desktop ya existe."
    fi
}

# ---------------------------------------------------------------------
# 7) Replicar en /root (modo --root)
# ---------------------------------------------------------------------
install_root() {
    if [ "$INSTALL_ROOT" -eq 1 ]; then
        say "Replicando configs en /root..."
        need_sudo
        sudo mkdir -p /root/.config
        sudo cp -a "$REPO_DIR/config/." /root/.config/ 2>/dev/null || true
        sudo install -D -m 600 "$REPO_DIR/home/.zshrc" /root/.zshrc
        sudo install -D -m 600 "$REPO_DIR/home/.p10k.zsh" /root/.p10k.zsh
        sudo chmod +x /root/.config/bspwm/bspwmrc /root/.config/bspwm/vm-resize.sh 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------
# 8) Recordatorios manuales (nmvim LSPs, Copilot)
# ---------------------------------------------------------------------
notes() {
    cat <<'EOF'

Hecho. Pasos manuales pendientes:
  * nvim    -> los LSPs se instalan bajo demanda con `:Mason`
  * Copilot -> dentro de nvim ejecuta `:Copilot auth` y sigue el codigo
               (red y root si usaste --root). Sin eso Copilot no responde.
  * Resize  -> tras redimensionar la ventana de la VM usa Super+Shift+R
  * Wallpaper: coloca tu imagen en ~/Pictures/retro1.png (bspwmrc la usa)
EOF
}

# ---------------------------------------------------------------------
main() {
    install_packages
    install_font
    install_p10k
    install_configs
    install_home
    install_session
    install_root
    notes
}

main "$@"