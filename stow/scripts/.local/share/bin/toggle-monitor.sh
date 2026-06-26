#!/bin/bash
# toggle-monitor.sh — alterna entre modo extendido y espejo (secundario → principal)
# Principal: DP-1 (1920x1080@180, volteado) | Secundario: HDMI-A-1 (1680x1050@60, vertical)

LOG="$HOME/.cache/.toggle-monitor.log"
STATE="$HOME/.cache/.monitor-toggle-state"

echo "=== $(date) ===" > "$LOG"

# ── Detectar monitores presentes ──
MON_NAMES=($(hyprctl monitors 2>>"$LOG" | grep "^Monitor" | awk '{print $2}'))
COUNT=${#MON_NAMES[@]}

echo "count=$COUNT names=${MON_NAMES[*]}" >> "$LOG"

# ── Identificar principal (DP-1) y secundario (HDMI-A-1) ──
for m in "${MON_NAMES[@]}"; do
    case "$m" in
        DP-*) MAIN="$m" ;;
        HDMI-*) SEC="$m" ;;
    esac
done

[ -z "$MAIN" ] && notify-send -a "Monitor" "Toggle Monitor" "Monitor principal (DP-*) no encontrado" -t 2000 && exit 1

echo "main=$MAIN sec=$SEC" >> "$LOG"

# ── Caso 1: Solo principal → nada que hacer ──
if [ -z "$SEC" ] && [ -f "$STATE" ] && grep -q "mirrored" "$STATE"; then
    # El secundario estaba espejado, pero ya no está conectado → limpiar estado
    echo "extended" > "$STATE"
    notify-send -a "Monitor" "Toggle Monitor" "Solo principal — estado limpiado" -t 2000
    exit 0
fi

if [ -z "$SEC" ]; then
    notify-send -a "Monitor" "Toggle Monitor" "Solo monitor principal conectado" -t 2000
    exit 0
fi

# ── Caso 2: Ambos monitores visibles → alternar ──
MIRRORED=$(hyprctl monitors 2>>"$LOG" | grep -A1 "^Monitor $SEC " | grep "mirrorOf" | grep -v "none")

if [ -z "$MIRRORED" ]; then
    # ═══ EXTENDIDO → ESPEJO ═══
    # Guardar posición y transform del secundario para restaurar después
    SEC_LINE=$(hyprctl monitors 2>>"$LOG" | grep -A1 "^Monitor $SEC " | tail -1)
    echo "saving: $SEC_LINE" >> "$LOG"

    # Extraer resolución y refresco: "1680x1050@59.95400 at 0x0"
    SEC_RES=$(echo "$SEC_LINE" | grep -oE '[0-9]+x[0-9]+@[0-9.]+' | head -1)
    # Fallback si no parsea
    [ -z "$SEC_RES" ] && SEC_RES="1680x1050@60"

    echo "mirrored" > "$STATE"
    echo "monitor=$SEC,$SEC_RES,0x0,1,transform,3" >> "$STATE"

    hyprctl keyword monitor "$SEC,preferred,auto,1,mirror,$MAIN" 2>>"$LOG"
    notify-send -a "Monitor" "Toggle Monitor" "Modo ESPEJO — secundario duplica al principal" -t 2000 -i display

else
    # ═══ ESPEJO → EXTENDIDO ═══
    if [ -f "$STATE" ] && grep -q "mirrored" "$STATE"; then
        SEC_CFG=$(grep "^monitor=" "$STATE" | head -1 | sed 's/^monitor=//')
        echo "restoring: $SEC_CFG" >> "$LOG"
        hyprctl keyword monitor "$SEC_CFG" 2>>"$LOG"
    else
        # Sin estado guardado: restaurar a defaults
        hyprctl keyword monitor "$SEC,1680x1050@60,0x0,1,transform,3" 2>>"$LOG"
    fi
    echo "extended" > "$STATE"

    sleep 0.5
    # Restaurar wallpaper en el monitor que reaparece
    WALLPAPER=$(readlink -f "$HOME/.config/hypr/current_wallpaper" 2>/dev/null)
    if [ -f "$WALLPAPER" ]; then
        swww img "$WALLPAPER" --transition-type none 2>>"$LOG" &
    fi

    notify-send -a "Monitor" "Toggle Monitor" "Modo EXTENDIDO" -t 2000 -i display
fi
