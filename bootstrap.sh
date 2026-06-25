#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

check_root() {
    if [ "$EUID" -eq 0 ]; then
        err "Do not run bootstrap.sh as root."
        exit 1
    fi
}

detect_distro() {
    if [ ! -f /etc/arch-release ]; then
        err "This bootstrap is designed for Arch Linux only."
        exit 1
    fi
    log "Arch Linux detected."
}

detect_aur_helper() {
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        warn "No AUR helper found. Installing paru..."
        sudo pacman -S --needed --noconfirm base-devel git
        TMPDIR=$(mktemp -d)
        git clone https://aur.archlinux.org/paru-bin.git "$TMPDIR/paru-bin"
        (cd "$TMPDIR/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$TMPDIR"
        AUR_HELPER="paru"
    fi
    log "AUR helper: $AUR_HELPER"
}

detect_nvidia() {
    if lspci -v 2>/dev/null | grep -qi 'nvidia\|3d controller.*nvidia'; then
        log "NVIDIA GPU detected. Applying NVIDIA env vars."
        NVIDIA=true
    elif [ -d /sys/module/nvidia ] || [ -d /sys/module/nvidia_drm ]; then
        NVIDIA=true
        log "NVIDIA kernel modules found."
    else
        NVIDIA=false
        log "No NVIDIA GPU detected."
    fi
}

install_packages() {
    log "Installing packages from pkglist.txt..."
    if [ ! -f "$DOTFILES_DIR/system/packages/pkglist.txt" ]; then
        warn "pkglist.txt not found. Skipping package installation."
        return
    fi

    # Install official repos first, then AUR
    grep -v '^#' "$DOTFILES_DIR/system/packages/pkglist.txt" | grep -v '^$' | \
    while read -r pkg; do
        if pacman -Si "$pkg" &>/dev/null; then
            echo "$pkg" >> "$DOTFILES_DIR/system/packages/_official.txt"
        else
            echo "$pkg" >> "$DOTFILES_DIR/system/packages/_aur.txt"
        fi
    done || true

    if [ -f "$DOTFILES_DIR/system/packages/_official.txt" ]; then
        sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/system/packages/_official.txt" || true
    fi

    if [ -f "$DOTFILES_DIR/system/packages/_aur.txt" ]; then
        $AUR_HELPER -S --needed --noconfirm - < "$DOTFILES_DIR/system/packages/_aur.txt" || true
    fi

    rm -f "$DOTFILES_DIR/system/packages/_official.txt" "$DOTFILES_DIR/system/packages/_aur.txt"
}

install_stow() {
    if ! command -v stow &>/dev/null; then
        log "Installing GNU Stow..."
        sudo pacman -S --needed --noconfirm stow
    fi
    log "GNU Stow ready."
}

install_nvidia_drivers() {
    if [ "$NVIDIA" = false ]; then
        return
    fi
    log "Installing NVIDIA drivers (open-dkms, recomendado para Ampere/RTX 3070)..."
    # linux-headers necesario para DKMS. nvidia-open-dkms = driver abierto (Turing+).
    sudo pacman -S --needed --noconfirm \
        nvidia-open-dkms nvidia-utils lib32-nvidia-utils \
        egl-wayland libva-nvidia-driver linux-headers 2>/dev/null || \
        warn "Algún paquete NVIDIA falló (revisa que multilib esté habilitado en /etc/pacman.conf)."
}

configure_nvidia_kernel() {
    if [ "$NVIDIA" = false ]; then
        return
    fi
    log "Configurando kernel para NVIDIA (modeset)..."

    # 1) Módulos en initramfs (orden importa)
    local mkc="/etc/mkinitcpio.conf"
    if [ -f "$mkc" ] && ! grep -qE '^MODULES=.*nvidia_drm' "$mkc"; then
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkc"
        # limpiar posible doble espacio
        sudo sed -i 's/MODULES=( /MODULES=(/' "$mkc"
        log "  Añadidos módulos nvidia a $mkc"
    fi

    # 2) Opciones del módulo (modeset + fbdev)
    echo 'options nvidia_drm modeset=1 fbdev=1' | \
        sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
    log "  /etc/modprobe.d/nvidia.conf escrito"

    # 3) Parámetro de kernel en GRUB (por si fbdev no basta)
    local grub="/etc/default/grub"
    if [ -f "$grub" ] && ! grep -q 'nvidia_drm.modeset=1' "$grub"; then
        sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia_drm.modeset=1"/' "$grub"
        log "  nvidia_drm.modeset=1 añadido a GRUB_CMDLINE_LINUX_DEFAULT"
    fi

    # 4) Regenerar initramfs + grub
    sudo mkinitcpio -P 2>/dev/null || warn "mkinitcpio falló; revísalo manualmente."
    if [ -f /boot/grub/grub.cfg ]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || \
            warn "grub-mkconfig falló; regenéralo manualmente."
    fi
    log "Kernel NVIDIA configurado. Requiere REBOOT."
}

apply_nvidia_config() {
    if [ "$NVIDIA" = false ]; then
        return
    fi

    local env_file="$HOME/.config/hypr/nvidia.conf"
    mkdir -p "$(dirname "$env_file")"

    cat > "$env_file" << 'EOF'
# NVIDIA env vars para Hyprland/Wayland (auto-generado por bootstrap.sh)
# Docs: https://wiki.hyprland.org/Nvidia/
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = NVD_BACKEND,direct
env = WLR_NO_HARDWARE_CURSORS,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# Cursores por software (evita cursor invisible/parpadeo en NVIDIA)
cursor {
    no_hardware_cursors = true
}

# Fix de cursor al iniciar
exec-once = hyprctl setcursor Bibata-Modern-Ice 20
EOF

    if ! grep -q "nvidia.conf" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
        echo "" >> "$HOME/.config/hypr/hyprland.conf"
        echo "# NVIDIA auto-config (añadido por bootstrap.sh)" >> "$HOME/.config/hypr/hyprland.conf"
        echo "source = ~/.config/hypr/nvidia.conf" >> "$HOME/.config/hypr/hyprland.conf"
    fi

    log "NVIDIA env vars escritos en nvidia.conf y enlazados en hyprland.conf."
}

run_stow() {
    log "Deploying dotfiles with GNU Stow..."
    cd "$DOTFILES_DIR/stow"

    local packages=(
        hyprland hyde waybar rofi dunst kitty fish starship
        fastfetch wlogout swaylock btop cava matugen foot
        fuzzel qt gtk scripts themes wallpaper home
        code networkmanager swappy
    )

    for pkg in "${packages[@]}"; do
        if [ -d "$pkg" ]; then
            log "  Stowing: $pkg"
            stow --target="$HOME" --restow "$pkg" 2>/dev/null || stow --target="$HOME" "$pkg"
        fi
    done

    log "Dotfiles deployed."
}

setup_sddm() {
    log "Setting up SDDM with OLED Mono theme..."

    local sddm_src="$DOTFILES_DIR/system/sddm"
    local theme_dir="/usr/share/sddm/themes/Sugar-Candy"

    sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg 2>/dev/null || true

    if [ ! -f "$theme_dir/Main.qml" ]; then
        log "Installing Sugar Candy SDDM theme..."
        $AUR_HELPER -S --needed --noconfirm sddm-theme-sugar-candy-git 2>/dev/null || true

        if [ ! -f "$theme_dir/Main.qml" ]; then
            warn "AUR install failed. Installing from git..."
            TMPDIR=$(mktemp -d)
            git clone https://github.com/Kangie/sddm-sugar-candy "$TMPDIR/sugar-candy"
            sudo mkdir -p "$theme_dir"
            sudo cp -r "$TMPDIR/sugar-candy/"* "$theme_dir/"
            rm -rf "$TMPDIR"
        fi
    fi

    sudo mkdir -p "$theme_dir/Backgrounds"
    sudo cp "$sddm_src/Backgrounds/lock-image.png" "$theme_dir/Backgrounds/"
    sudo cp "$sddm_src/theme.conf.user" "$theme_dir/"
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$sddm_src/sddm.conf.d-10-oled-mono.conf" /etc/sddm.conf.d/10-oled-mono.conf

    CURR_DM=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null || true)
    if [ -n "$CURR_DM" ] && [ "$CURR_DM" != "sddm" ]; then
        sudo systemctl disable "$CURR_DM" 2>/dev/null || true
    fi
    sudo systemctl enable sddm 2>/dev/null || true

    log "SDDM configured with OLED Mono theme."
}

generate_colors() {
    if command -v matugen &>/dev/null; then
        log "Generating initial color scheme with matugen..."
        local wallpaper
        wallpaper=$(find "$HOME/Wallpapers" -type f \( -name "*.gif" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | head -1)
        if [ -n "$wallpaper" ]; then
            matugen image "$wallpaper" 2>/dev/null || true
            log "Colors generated from $wallpaper"
        fi
    fi
}

final_message() {
    echo ""
    echo -e "  ${CYAN}==========================================${NC}"
    echo -e "  ${GREEN}Dotfiles installation complete!${NC}"
    echo -e "  ${CYAN}==========================================${NC}"
    echo ""
    echo -e "  Packages installed from: system/packages/pkglist.txt"
    echo -e "  AUR helper used:        ${YELLOW}${AUR_HELPER}${NC}"
    echo -e "  NVIDIA detected:         ${YELLOW}${NVIDIA}${NC}"
    echo ""
    echo -e "  ${YELLOW}Próximos pasos:${NC}"
    echo -e "  1. Pega tus wallpapers (gifs OLED Mono) — NO están en el repo:"
    echo -e "     copia samurai.gif / swordbyn.gif / vagabond.gif dentro de"
    echo -e "     ${CYAN}~/Wallpapers/${NC}  (o en stow/wallpaper/Wallpapers/ antes de stow)"
    echo -e "  2. Pon tu API key:  ${CYAN}cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish${NC}"
    echo -e "  3. Revisa el layout de monitores en ${CYAN}~/.config/hypr/monitors.conf${NC}"
    echo -e "     (corre ${CYAN}hyprctl monitors all${NC} para ver los nombres reales de puertos)"
    if [ "$NVIDIA" = true ]; then
        echo -e "  4. ${YELLOW}NVIDIA detectada:${NC} se instalaron drivers + kernel modeset."
        echo -e "     ${RED}REINICIA${NC} para cargar los módulos nvidia y activar SDDM."
    else
        echo -e "  4. Reinicia para activar SDDM en el login."
    fi
    echo ""
    echo -e "  5. Si los iconos/cursor fallan, instala:"
    echo -e "     ${CYAN}\$AUR_HELPER -S tela-circle-icon-theme-git bibata-cursor-theme${NC}"
    echo ""
    echo -e "  ${GREEN}¡Disfruta tu setup!${NC}"
    echo ""
}

main() {
    check_root
    detect_distro
    detect_aur_helper
    detect_nvidia
    install_packages
    install_nvidia_drivers
    install_stow
    run_stow
    apply_nvidia_config
    configure_nvidia_kernel
    setup_sddm
    generate_colors
    final_message
}

main "$@"
