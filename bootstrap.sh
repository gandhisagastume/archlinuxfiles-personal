#!/usr/bin/env bash
#
# bootstrap.sh — Instala dotfiles completos en Arch Linux
#
# Uso:
#   ./bootstrap.sh                  # instalación completa
#   ./bootstrap.sh --dry-run        # muestra qué haría sin ejecutar
#   ./bootstrap.sh --skip-packages  # no instala paquetes (ya están)
#   ./bootstrap.sh --skip-nvidia    # no configura NVIDIA
#   ./bootstrap.sh --skip-sddm      # no configura SDDM
#   ./bootstrap.sh --help           # muestra ayuda
#
# Variables de entorno:
#   DOTFILES_DIR  - ubicación del repo (auto-detectado)
#   DOTFILES_USER - nombre de usuario target (default: $USER)
#   AUR_HELPER    - helper AUR forzado: paru|yay (default: auto)

set -eo pipefail

# ┌────────────────────────────────────────────────────────────────┐
# │ CONFIGURACIÓN                                                     │
# └────────────────────────────────────────────────────────────────┘

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR

# Colores
if [ -t 1 ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Flags
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_NVIDIA=false
SKIP_SDDM=false
SKIP_STOW=false
SKIP_THEMES=false
VERBOSE=false
NVIDIA=false
AUR_HELPER=""

# Lista de paquetes stow (orden importa)
STOW_PACKAGES=(
    hyprland hyde waybar rofi dunst kitty fish starship
    fastfetch wlogout swaylock btop cava matugen foot
    fuzzel qt gtk scripts themes wallpaper home
    code networkmanager swappy terminalphoto
)

# ┌────────────────────────────────────────────────────────────────┐
# │ FUNCIONES DE LOGGING                                                │
# └────────────────────────────────────────────────────────────────┘

log()   { printf "${GREEN}[+]${NC} %s\n" "$*"; }
info()  { printf "${CYAN}[i]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$*" >&2; }
err()   { printf "${RED}[x]${NC} %s\n" "$*" >&2; }
debug() { [ "$VERBOSE" = true ] && printf "${BLUE}[D]${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
fail()  { err "$*"; exit 1; }

section() {
    printf "\n${BOLD}${CYAN}━━━ %s ━━━${NC}\n" "$*"
}

# Wrapper que respeta dry-run
run() {
    if [ "$DRY_RUN" = true ]; then
        printf "${YELLOW}[DRY]${NC} %s\n" "$*"
    else
        debug "RUN: $*"
        "$@"
    fi
}

sudo_run() {
    if [ "$DRY_RUN" = true ]; then
        printf "${YELLOW}[DRY]${NC} sudo %s\n" "$*"
    else
        debug "SUDO: $*"
        sudo "$@"
    fi
}

# ┌────────────────────────────────────────────────────────────────┐
# │ ARGUMENTOS                                                          │
# └────────────────────────────────────────────────────────────────┘

usage() {
    cat <<'EOF'
bootstrap.sh — Instala dotfiles completos en Arch Linux

Uso: ./bootstrap.sh [opciones]

Opciones:
  --dry-run          Muestra qué haría sin ejecutar nada
  --skip-packages    No instala paquetes (útil si ya están)
  --skip-nvidia      No configura drivers/kernel NVIDIA
  --skip-sddm        No instala/configura SDDM
  --skip-stow        No aplica symlinks con stow
  --skip-themes      No aplica temas GTK/Qt
  --verbose          Muestra más detalles
  --help, -h         Muestra esta ayuda

Variables de entorno:
  AUR_HELPER=paru|yay   Forzar helper AUR (default: auto-detect)

Ejemplos:
  ./bootstrap.sh                    # instalación completa
  ./bootstrap.sh --skip-packages    # asume paquetes ya instalados
  ./bootstrap.sh --dry-run          # simular sin hacer nada
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)        DRY_RUN=true ;;
            --skip-packages)  SKIP_PACKAGES=true ;;
            --skip-nvidia)    SKIP_NVIDIA=true ;;
            --skip-sddm)      SKIP_SDDM=true ;;
            --skip-stow)      SKIP_STOW=true ;;
            --skip-themes)    SKIP_THEMES=true ;;
            --verbose|-v)     VERBOSE=true ;;
            --help|-h)        usage; exit 0 ;;
            *)                err "Opción desconocida: $1"; usage; exit 1 ;;
        esac
        shift
    done
}

# ┌────────────────────────────────────────────────────────────────┐
# │ VALIDACIONES PREVIAS                                                │
# └────────────────────────────────────────────────────────────────┘

check_root() {
    if [ "$EUID" -eq 0 ]; then
        fail "No ejecutes bootstrap.sh como root. Usa tu usuario normal."
    fi
}

check_distro() {
    if [ ! -f /etc/arch-release ] && ! command -v pacman &>/dev/null; then
        fail "Este script es para Arch Linux. Detectado: $(cat /etc/os-release 2>/dev/null | grep PRETTY | head -1 || echo 'desconocido')"
    fi
    info "Sistema: Arch Linux ($(uname -m))"
}

check_network() {
    if ! ping -c 1 -W 3 archlinux.org &>/dev/null && \
       ! curl -s --max-time 3 -o /dev/null https://github.com; then
        warn "Sin conexión a internet. Algunas funciones fallarán."
    else
        info "Red: OK"
    fi
}

check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR/stow" ] || [ ! -f "$DOTFILES_DIR/bootstrap.sh" ]; then
        fail "Estructura de dotfiles inválida en $DOTFILES_DIR"
    fi
    info "Dotfiles en: $DOTFILES_DIR"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ DETECCIÓN DE HARDWARE                                               │
# └────────────────────────────────────────────────────────────────┘

detect_nvidia() {
    section "Detectando GPU"
    if lspci -mm 2>/dev/null | grep -qi 'nvidia'; then
        NVIDIA=true
        local gpu=$(lspci -mm 2>/dev/null | grep -i 'nvidia' | head -1 | sed 's/^"\([^"]*\)".*/\1/')
        ok "GPU NVIDIA detectada: $gpu"
    elif [ -d /sys/module/nvidia ] || [ -d /sys/module/nvidia_drm ]; then
        NVIDIA=true
        warn "Módulos NVIDIA ya cargados (post-boot)"
    else
        NVIDIA=false
        info "Sin GPU NVIDIA"
    fi
    if [ "$NVIDIA" = true ] && [ "$SKIP_NVIDIA" = false ]; then
        log "Se aplicará configuración NVIDIA"
    fi
}

# ┌────────────────────────────────────────────────────────────────┐
# │ AUR HELPER                                                          │
# └────────────────────────────────────────────────────────────────┘

detect_aur_helper() {
    section "AUR helper"
    if [ -n "$AUR_HELPER" ]; then
        if command -v "$AUR_HELPER" &>/dev/null; then
            ok "Forzado: $AUR_HELPER"
            return
        else
            warn "$AUR_HELPER no instalado, intentando auto-detectar"
        fi
    fi
    if command -v paru &>/dev/null; then
        AUR_HELPER=paru
    elif command -v yay &>/dev/null; then
        AUR_HELPER=yay
    else
        warn "No se encontró AUR helper. Instalando paru..."
        sudo_run pacman -S --needed --noconfirm base-devel git
        local tmp
        tmp=$(mktemp -d)
        run git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && run makepkg -si --noconfirm)
        rm -rf "$tmp"
        AUR_HELPER=paru
    fi
    ok "AUR helper: $AUR_HELPER"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ PAQUETES                                                             │
# └────────────────────────────────────────────────────────────────┘

install_packages() {
    section "Instalando paquetes"
    local pkglist="$DOTFILES_DIR/system/packages/pkglist.txt"
    if [ ! -f "$pkglist" ]; then
        warn "No existe $pkglist, saltando"
        return
    fi

    # Separar oficiales vs AUR
    local tmpdir
    tmpdir=$(mktemp -d)
    local official="$tmpdir/official.txt"
    local aur="$tmpdir/aur.txt"
    > "$official"
    > "$aur"

    while IFS= read -r pkg; do
        # Ignorar comentarios y líneas vacías
        case "$pkg" in '#'*) continue ;; '') continue ;; esac
        if pacman -Si "$pkg" &>/dev/null; then
            echo "$pkg" >> "$official"
        else
            echo "$pkg" >> "$aur"
        fi
    done < "$pkglist"

    local official_count aur_count
    official_count=$(wc -l < "$official" 2>/dev/null || echo 0)
    aur_count=$(wc -l < "$aur" 2>/dev/null || echo 0)

    info "Repos oficiales: $official_count paquetes"
    info "AUR: $aur_count paquetes"

    if [ "$official_count" -gt 0 ]; then
        log "Instalando paquetes oficiales..."
        # shellcheck disable=SC2046
        sudo_run pacman -S --needed --noconfirm $(cat "$official") || warn "Algunos paquetes oficiales fallaron"
    fi

    if [ "$aur_count" -gt 0 ]; then
        log "Instalando paquetes AUR..."
        # shellcheck disable=SC2046
        run $AUR_HELPER -S --needed --noconfirm $(cat "$aur") || warn "Algunos paquetes AUR fallaron"
    fi

    rm -rf "$tmpdir"
    ok "Paquetes instalados"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ STOW                                                                 │
# └────────────────────────────────────────────────────────────────┘

run_stow() {
    section "Aplicando dotfiles (GNU Stow)"
    cd "$DOTFILES_DIR/stow"

    local count=0
    local failed=()
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$pkg" ]; then
            printf "  ${CYAN}stow${NC} %-20s ... " "$pkg"
            if [ "$DRY_RUN" = true ]; then
                echo "${YELLOW}[DRY]${NC}"
            elif stow --target="$HOME" --restow "$pkg" 2>/dev/null || \
                 stow --target="$HOME" "$pkg" 2>/dev/null; then
                echo "${GREEN}OK${NC}"
                count=$((count + 1))
            else
                echo "${RED}FAIL${NC}"
                failed+=("$pkg")
            fi
        else
            printf "  ${CYAN}stow${NC} %-20s ... ${YELLOW}SKIP (no existe)${NC}\n" "$pkg"
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        warn "Fallaron: ${failed[*]}"
    fi
    ok "Stowed $count/${#STOW_PACKAGES[@]} paquetes"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ NVIDIA                                                               │
# └────────────────────────────────────────────────────────────────┘

install_nvidia_drivers() {
    [ "$NVIDIA" = true ] || return
    section "Drivers NVIDIA (open-dkms, recomendado Ampere+)"
    sudo_run pacman -S --needed --noconfirm \
        nvidia-open-dkms nvidia-utils lib32-nvidia-utils \
        egl-wayland libva-nvidia-driver linux-headers \
        || warn "Revisa que [multilib] esté habilitado en /etc/pacman.conf"
    ok "Drivers NVIDIA instalados"
}

configure_nvidia_kernel() {
    [ "$NVIDIA" = true ] || return
    section "Configurando kernel para NVIDIA"

    # 1) Initramfs
    local mkc="/etc/mkinitcpio.conf"
    if [ -f "$mkc" ]; then
        if ! grep -qE '^MODULES=.*nvidia_drm' "$mkc"; then
            sudo_run sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkc"
            sudo_run sed -i 's/MODULES=( /MODULES=(/' "$mkc"
            ok "Módulos nvidia añadidos a $mkc"
        else
            info "Módulos nvidia ya en initramfs"
        fi
    fi

    # 2) Modprobe
    echo 'options nvidia_drm modeset=1 fbdev=1' | sudo_run tee /etc/modprobe.d/nvidia.conf >/dev/null
    ok "/etc/modprobe.d/nvidia.conf escrito"

    # 3) GRUB
    local grub="/etc/default/grub"
    if [ -f "$grub" ]; then
        if ! grep -q 'nvidia_drm.modeset=1' "$grub"; then
            sudo_run sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia_drm.modeset=1"/' "$grub"
            ok "nvidia_drm.modeset=1 añadido a GRUB"
        else
            info "Parámetro GRUB ya presente"
        fi
    fi

    # 4) Regenerar
    sudo_run mkinitcpio -P || warn "mkinitcpio falló"
    if [ -f /boot/grub/grub.cfg ]; then
        sudo_run grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig falló"
    fi
    ok "Kernel NVIDIA configurado (requiere REBOOT)"
}

apply_nvidia_env() {
    [ "$NVIDIA" = true ] || return
    section "NVIDIA env vars (Hyprland/Wayland)"

    local env_file="$HOME/.config/hypr/nvidia.conf"
    mkdir -p "$(dirname "$env_file")"

    cat > "$env_file" <<'EOF'
# NVIDIA env vars para Hyprland/Wayland (auto-generado por bootstrap.sh)
# Docs: https://wiki.hyprland.org/Nvidia/
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = NVD_BACKEND,direct
env = WLR_NO_HARDWARE_CURSORS,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# Cursores por software (evita cursor invisible en NVIDIA)
cursor {
    no_hardware_cursors = true
}

# Fix cursor al iniciar
exec-once = hyprctl setcursor Bibata-Modern-Ice 20
EOF

    local hlconf="$HOME/.config/hypr/hyprland.conf"
    if ! grep -q "nvidia.conf" "$hlconf" 2>/dev/null; then
        {
            echo ""
            echo "# NVIDIA auto-config (añadido por bootstrap.sh)"
            echo "source = ~/.config/hypr/nvidia.conf"
        } >> "$hlconf"
        ok "nvidia.conf enlazado en hyprland.conf"
    else
        info "nvidia.conf ya enlazado"
    fi
    ok "NVIDIA env vars listos"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ SDDM                                                                 │
# └────────────────────────────────────────────────────────────────┘

setup_sddm() {
    section "SDDM con tema OLED Mono"
    local sddm_src="$DOTFILES_DIR/system/sddm"
    local theme_dir="/usr/share/sddm/themes/Sugar-Candy"

    sudo_run pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg 2>/dev/null || true

    # Instalar Sugar Candy
    if [ ! -f "$theme_dir/Main.qml" ]; then
        log "Instalando Sugar Candy SDDM theme..."
        run $AUR_HELPER -S --needed --noconfirm sddm-theme-sugar-candy-git 2>/dev/null || true

        if [ ! -f "$theme_dir/Main.qml" ]; then
            warn "AUR falló, instalando desde git..."
            local tmp
            tmp=$(mktemp -d)
            run git clone https://github.com/Kangie/sddm-sugar-candy "$tmp/sugar-candy"
            sudo_run mkdir -p "$theme_dir"
            sudo_run cp -r "$tmp/sugar-candy/"* "$theme_dir/"
            rm -rf "$tmp"
        fi
    else
        info "Sugar Candy ya instalado"
    fi

    # Copiar background + theme
    sudo_run mkdir -p "$theme_dir/Backgrounds"
    sudo_run cp "$sddm_src/Backgrounds/lock-image.png" "$theme_dir/Backgrounds/"
    sudo_run cp "$sddm_src/theme.conf.user" "$theme_dir/"

    # SDDM main config
    sudo_run mkdir -p /etc/sddm.conf.d
    sudo_run cp "$sddm_src/sddm.conf.d-10-oled-mono.conf" /etc/sddm.conf.d/10-oled-mono.conf
    ok "SDDM configs copiados"

    # Customizaciones (animated GIF, Japanese clock)
    log "Aplicando customizaciones SDDM..."
    [ -f "$sddm_src/animated-fix.sh" ] && run bash "$sddm_src/animated-fix.sh" 2>/dev/null || true
    [ -f "$sddm_src/japanese-clock.sh" ] && run bash "$sddm_src/japanese-clock.sh" 2>/dev/null || true

    # Habilitar SDDM
    local curr_dm
    curr_dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null || true)
    if [ -n "$curr_dm" ] && [ "$curr_dm" != "sddm" ]; then
        info "Deshabilitando $curr_dm, habilitando sddm"
        sudo_run systemctl disable "$curr_dm" 2>/dev/null || true
    fi
    sudo_run systemctl enable sddm 2>/dev/null || true
    ok "SDDM listo (OLED Mono + ようこそ + animated GIF)"
}

# ┌────────────────────────────────────────────────────────────────┐
# │ TEMAS Y COLORES                                                     │
# └────────────────────────────────────────────────────────────────┘

apply_themes() {
    section "Aplicando temas"
    # Activar OLED Mono via hyde.conf
    local hydeconf="$HOME/.config/hyde/hyde.conf"
    if [ -f "$hydeconf" ] && ! grep -q 'hydeTheme="OLED Mono"' "$hydeconf"; then
        run sed -i 's/^hydeTheme=.*/hydeTheme="OLED Mono"/' "$hydeconf"
        ok "hydeTheme = OLED Mono"
    fi
    # Generar colores iniciales con matugen
    if command -v matugen &>/dev/null; then
        local wp
        wp=$(find "$HOME/Wallpapers" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" \) 2>/dev/null | head -1)
        if [ -n "$wp" ]; then
            log "Generando colores con matugen desde $(basename "$wp")..."
            run matugen image "$wp" 2>/dev/null || true
            ok "Colores generados"
        else
            warn "Sin wallpapers para matugen (saltando)"
        fi
    fi
}

# ┌────────────────────────────────────────────────────────────────┐
# │ SECRETS                                                              │
# └────────────────────────────────────────────────────────────────┘

setup_secrets() {
    section "Secrets"
    local secrets_example="$HOME/.config/fish/secrets.fish.example"
    local secrets_real="$HOME/.config/fish/secrets.fish"
    if [ -f "$secrets_example" ] && [ ! -f "$secrets_real" ]; then
        warn "Secrets no configurados:"
        warn "  cp $secrets_example $secrets_real"
        warn "  # edita con tus claves reales"
    elif [ -f "$secrets_real" ]; then
        ok "Secrets configurados"
    fi
}

# ┌────────────────────────────────────────────────────────────────┐
# │ POST-INSTALL                                                         │
# └────────────────────────────────────────────────────────────────┘

post_install_summary() {
    section "Post-instalación"
    echo ""
    echo -e "${BOLD}${GREEN}  ✓ Dotfiles instalados${NC}"
    echo ""
    echo -e "  ${CYAN}Resumen:${NC}"
    echo -e "    • AUR helper:  ${YELLOW}${AUR_HELPER}${NC}"
    echo -e "    • NVIDIA:      ${YELLOW}${NVIDIA}${NC}"
    echo -e "    • Display:     ${YELLOW}SDDM (Sugar Candy OLED Mono)${NC}"
    echo -e "    • WM:          ${YELLOW}Hyprland (HyDE)${NC}"
    echo -e "    • Theme:       ${YELLOW}OLED Mono${NC}"
    echo ""
    echo -e "  ${BOLD}Próximos pasos:${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Wallpapers animados (NO en git por tamaño):"
    echo -e "     ${CYAN}# Pega tus gifs en ~/Wallpapers/"
    echo -e "     # O copia stow/wallpaper/Wallpapers/{samurai,swordbyn,vagabond}.gif"
    echo -e "     # desde tu backup → ${HOME}/Wallpapers/${NC}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Configurar secrets:"
    echo -e "     ${CYAN}cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish"
    echo -e "     \$EDITOR ~/.config/fish/secrets.fish${NC}"
    echo ""
    echo -e "  ${YELLOW}3.${NC} Verificar monitores:"
    echo -e "     ${CYAN}hyprctl monitors all${NC}  # ver nombres reales (DP-1, HDMI-A-1...)"
    echo -e "     ${CYAN}\$EDITOR ~/.config/hypr/monitors.conf${NC}  # ajustar si necesario"
    echo ""
    if [ "$NVIDIA" = true ]; then
        echo -e "  ${YELLOW}4.${NC} ${RED}${BOLD}REINICIAR${NC} (carga drivers NVIDIA y SDDM)"
        echo -e "     ${CYAN}sudo reboot${NC}"
    else
        echo -e "  ${YELLOW}4.${NC} Reiniciar (activar SDDM)"
        echo -e "     ${CYAN}sudo reboot${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}5.${NC} Post-reboot:"
    echo -e "     ${CYAN}Super+Shift+T${NC}     → selector de wallpaper"
    echo -e "     ${CYAN}Super+Shift+A${NC}     → selector de rofi style"
    echo -e "     ${CYAN}Super+Y${NC}           → selector de theme HyDE"
    echo -e "     ${CYAN}Super+/ ${NC}          → ver todos los keybinds"
    echo ""
    if [ "$NVIDIA" = true ]; then
        echo -e "  ${YELLOW}6.${NC} Verificar NVIDIA:"
        echo -e "     ${CYAN}nvidia-smi${NC}  # debe mostrar tu RTX 3070"
    fi
    echo ""
    echo -e "  ${BOLD}Documentación:${NC} ${CYAN}$DOTFILES_DIR/README.md${NC}"
    echo ""
}

# ┌────────────────────────────────────────────────────────────────┐
# │ MAIN                                                                 │
# └────────────────────────────────────────────────────────────────┘

main() {
    parse_args "$@"

    printf "${BOLD}${CYAN}"
    cat <<'EOF'
  ┌──────────────────────────────────────────┐
  │  archlinuxfiles-personal bootstrap       │
  │  Hyprland + HyDE (OLED Mono) + NVIDIA   │
  └──────────────────────────────────────────┘
EOF
    printf "${NC}\n"

    if [ "$DRY_RUN" = true ]; then
        warn "MODO DRY-RUN: no se hará ningún cambio"
    fi

    # 1) Validaciones
    section "Validaciones"
    check_root
    check_distro
    check_network
    check_dotfiles_dir
    ok "Todo OK para continuar"

    # 2) AUR helper (lo necesitamos antes de instalar paquetes)
    detect_aur_helper

    # 3) Detección de hardware
    detect_nvidia

    # 4) Instalar paquetes
    if [ "$SKIP_PACKAGES" = true ]; then
        info "Saltando instalación de paquetes (--skip-packages)"
    else
        install_packages
    fi

    # 5) Stow
    if [ "$SKIP_STOW" = true ]; then
        info "Saltando stow (--skip-stow)"
    else
        run_stow
    fi

    # 6) NVIDIA
    if [ "$SKIP_NVIDIA" = true ]; then
        info "Saltando NVIDIA (--skip-nvidia)"
    elif [ "$NVIDIA" = true ]; then
        install_nvidia_drivers
        configure_nvidia_kernel
        apply_nvidia_env
    fi

    # 7) SDDM
    if [ "$SKIP_SDDM" = true ]; then
        info "Saltando SDDM (--skip-sddm)"
    else
        setup_sddm
    fi

    # 8) Temas y colores
    if [ "$SKIP_THEMES" = true ]; then
        info "Saltando temas (--skip-themes)"
    else
        apply_themes
    fi

    # 9) Secrets
    setup_secrets

    # 10) Resumen
    if [ "$DRY_RUN" = true ]; then
        echo ""
        warn "DRY-RUN completado. Sin cambios."
    else
        post_install_summary
    fi
}

main "$@"
