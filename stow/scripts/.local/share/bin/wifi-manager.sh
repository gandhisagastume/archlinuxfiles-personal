#!/usr/bin/env sh

# Script para abrir WiFi manager con networkmanager-dmenu

if command -v networkmanager_dmenu &> /dev/null; then
    networkmanager_dmenu
else
    notify-send "networkmanager-dmenu no está instalado" "Instala con: sudo pacman -S networkmanager-dmenu"
fi
