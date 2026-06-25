#!/usr/bin/env sh

# Script para abrir TLP UI (interfaz gráfica de TLP)

if command -v tlpui &> /dev/null; then
    tlpui &
else
    notify-send "TLP UI no está instalado" "Instala con: yay -S tlpui"
fi
