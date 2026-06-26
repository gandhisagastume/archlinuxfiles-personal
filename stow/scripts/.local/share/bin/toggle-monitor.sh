#!/bin/bash

LOG=$HOME/.toggle-monitor.log
STATE=$HOME/.cache/.monitor-toggle-state

echo "=== $(date) ===" > "$LOG"

MONITORS=$(hyprctl monitors -j 2>>"$LOG")
COUNT=$(echo "$MONITORS" | jq 'length')
echo "COUNT: $COUNT" >> "$LOG"

if [ "$COUNT" -ge 2 ]; then
    # ====== 2+ monitores visibles → EXTENDIDO → activar ESPEJO ======
    NAME1=$(echo "$MONITORS" | jq -r '.[0].name')
    NAME2=$(echo "$MONITORS" | jq -r '.[1].name')
    WIDTH=$(echo "$MONITORS" | jq -r '.[0].width')
    SCALE2=$(echo "$MONITORS" | jq -r '.[1].scale')

    echo "ACTION: mirror $NAME2 -> $NAME1 (save: ${NAME2},preferred,${WIDTH}x0,${SCALE2})" >> "$LOG"

    # Guardar config de extend para volver después
    echo "mirrored" > "$STATE"
    echo "monitor=${NAME2},preferred,${WIDTH}x0,${SCALE2}" >> "$STATE"

    hyprctl keyword monitor "${NAME2},preferred,auto,${SCALE2},mirror,${NAME1}" 2>>"$LOG"
    notify-send -a "Monitor" "Toggle Monitor" "Modo espejo / duplicado" -t 2000 -i display

elif [ -f "$STATE" ] && grep -q "mirrored" "$STATE"; then
    # ====== 1 monitor visible + estado "mirrored" → desactivar ESPEJO → EXTENDER ======
    SECONDARY=$(grep "monitor=" "$STATE" | head -1 | sed 's/^monitor=//')
    echo "ACTION: unmirror → $SECONDARY" >> "$LOG"

    hyprctl keyword monitor "$SECONDARY" 2>>"$LOG"
    echo "extended" > "$STATE"

    sleep 0.5
    WALLPAPER=$(readlink -f "$HOME/.config/hypr/current_wallpaper" 2>/dev/null)
    if [ -f "$WALLPAPER" ]; then
        swww img "$WALLPAPER" --transition-type none 2>>"$LOG" &
    fi

    notify-send -a "Monitor" "Toggle Monitor" "Modo extendido" -t 2000 -i display

else
    notify-send -a "Monitor" "Toggle Monitor" "Solo hay un monitor conectado" -t 2000
fi
