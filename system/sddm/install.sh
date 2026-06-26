#!/bin/bash
# OLED Mono SDDM Setup Script - Fixed version
# Installs SDDM + Sugar Candy theme with OLED Mono colors

set -e

echo ""
echo "  OLED Mono SDDM Setup"
echo "  ===================="
echo ""

THEME_DIR="/usr/share/sddm/themes/Sugar-Candy"

# --------------------------------------------------
# Step 1: Install SDDM and Qt5 dependencies
# --------------------------------------------------
echo "  [1/6] Installing SDDM and Qt5 dependencies..."
sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg

# --------------------------------------------------
# Step 2: Install Sugar Candy theme from AUR
# --------------------------------------------------
echo "  [2/6] Installing Sugar Candy theme..."

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

if [ -n "$AUR_HELPER" ]; then
    echo "  Installing via $AUR_HELPER..."
    $AUR_HELPER -S --rebuild --noconfirm sddm-theme-sugar-candy-git 2>/dev/null || true
fi

if [ ! -f "$THEME_DIR/Main.qml" ]; then
    echo "  AUR didn't work. Installing manually from git..."
    TMPDIR=$(mktemp -d)
    git clone https://github.com/Kangie/sddm-sugar-candy.git "$TMPDIR/sugar-candy"
    sudo mkdir -p "$THEME_DIR"
    (cd "$TMPDIR/sugar-candy" && sudo find . -type f -print0 | while IFS= read -r -d '' f; do
        dest="${f#./}"
        sudo install -Dm644 "$f" "$THEME_DIR/$dest"
    done)
    rm -rf "$TMPDIR"
fi

if [ ! -f "$THEME_DIR/Main.qml" ]; then
    echo ""
    echo "  ERROR: Sugar Candy not found at $THEME_DIR"
    exit 1
fi
echo "  Sugar Candy found at $THEME_DIR"

# --------------------------------------------------
# Step 3: Copy background image
# --------------------------------------------------
echo "  [3/6] Installing OLED Mono background image..."
sudo mkdir -p "$THEME_DIR/Backgrounds"
sudo cp "$HOME/.config/hyde/sddm/Backgrounds/lock-image.png" "$THEME_DIR/Backgrounds/lock-image.png"
echo "  lock-image.png → $THEME_DIR/Backgrounds/"

# --------------------------------------------------
# Step 4: Apply OLED Mono theme.conf.user
# --------------------------------------------------
echo "  [4/6] Applying OLED Mono colors..."
sudo cp "$HOME/.config/hyde/sddm/theme.conf.user" "$THEME_DIR/theme.conf.user"
echo "  theme.conf.user → $THEME_DIR/"

# --------------------------------------------------
# Step 5: Configure SDDM (theme + keyboard + numlock)
# --------------------------------------------------
echo "  [5/6] Configuring SDDM..."
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$HOME/.config/hyde/sddm/sddm.conf.d-10-oled-mono.conf" /etc/sddm.conf.d/10-oled-mono.conf
echo "  config → /etc/sddm.conf.d/10-oled-mono.conf"
echo "  Keyboard layout: es | Numlock: on"

# --------------------------------------------------
# Step 6: Enable SDDM service
# --------------------------------------------------
echo "  [6/6] Enabling SDDM service..."
if [ -f /etc/systemd/system/display-manager.service ]; then
    CURRENT_DM=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service 2>/dev/null)
    if [ -n "$CURRENT_DM" ] && [ "$CURRENT_DM" != "sddm" ]; then
        echo "  Disabling $CURRENT_DM..."
        sudo systemctl disable "$CURRENT_DM" 2>/dev/null || true
    fi
fi
sudo systemctl enable sddm 2>/dev/null || true

echo ""
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │  OLED Mono SDDM is ready                             │"
echo "  │                                                      │"
echo "  │  Background: lock-image.png (full, not cropped)      │"
echo "  │  Blur:      soft (radius 25)                         │"
echo "  │  Form:      centered, dark glass panel               │"
echo "  │  Text:      white, JetBrainsMono Nerd Font           │"
echo "  │                                                      │"
echo "  │  IMPORTANT: Check what DM is running:                │"
echo "  │    systemctl status display-manager                  │"
echo "  │                                                      │"
echo "  │  If you see another DM (ly, greetd, etc):            │"
echo "  │    sudo systemctl disable <other-dm>                 │"
echo "  │    sudo systemctl enable sddm                        │"
echo "  │                                                      │"
echo "  │  EMERGENCY: Ctrl+Alt+F3 for TTY                      │"
echo "  │                                                      │"
echo "  │  Reboot:                                             │"
echo "  │    sudo reboot                                       │"
echo "  └──────────────────────────────────────────────────────┘"
echo ""
