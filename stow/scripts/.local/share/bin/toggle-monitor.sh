#!/bin/bash
# toggle-monitor.sh — alterna entre modo extendido y espejo (secundario → principal)
# Principal: DP-1 (1920x1080@180, volteado) | Secundario: HDMI-A-1 (1680x1050@60, vertical)

LOG="$HOME/.cache/.toggle-monitor.log"
STATE="$HOME/.cache/.monitor-toggle-state"

echo "=== $(date) ===" > "$LOG"

# ── Detectar monitores visibles ──
MON_NAMES=($(hyprctl monitors 2>>"$LOG" | grep "^Monitor" | awk '{print $2}'))
COUNT=${#MON_NAMES[@]}

echo "count=$COUNT names=${MON_NAMES[*]}" >> "$LOG"

# ── Identificar principal (DP-*) y secundario (HDMI-*) ──
PRIMARY_DETECTED=""
SECONDARY_DETECTED=""
for m in "${MON_NAMES[@]}"; do
    case "$m" in
        DP-*) PRIMARY_DETECTED="$m" ;;
        HDMI-*) SECONDARY_DETECTED="$m" ;;
    esac
done

# ── Resolver nombres: priorizar detectados, fallback a defaults ──
MAIN="${PRIMARY_DETECTED:-DP-1}"
SEC="${SECONDARY_DETECTED:-HDMI-A-1}"

echo "main=$MAIN sec=$SEC detected_sec=$SECONDARY_DETECTED" >> "$LOG"

# ── Leer estado ──
STATE_MODE="extended"
[ -f "$STATE" ] && grep -q "mirrored" "$STATE" && STATE_MODE="mirrored"
echo "state_mode=$STATE_MODE" >> "$LOG"

# ── LÓGICA PRINCIPAL ──

if [ -z "$SECONDARY_DETECTED" ] && [ "$STATE_MODE" = "mirrored" ]; then
    # ═══ ESPEJO → EXTENDIDO (secundario oculto por mirror) ═══
    if [ -f "$STATE" ]; then
        SEC_CFG=$(grep "^monitor=" "$STATE" | head -1 | sed 's/^monitor=//')
        echo "restoring saved: $SEC_CFG" >> "$LOG"
        if [ -n "$SEC_CFG" ]; then
            hyprctl keyword monitor "$SEC_CFG" 2>>"$LOG"
        else
            hyprctl keyword monitor "$SEC,1680x1050@60,0x0,1,transform,1" 2>>"$LOG"
        fi
    else
        hyprctl keyword monitor "$SEC,1680x1050@60,0x0,1,transform,1" 2>>"$LOG"
    fi
    echo "extended" > "$STATE"

    sleep 0.5
    WALLPAPER=$(readlink -f "$HOME/.config/hypr/current_wallpaper" 2>/dev/null)
    [ -f "$WALLPAPER" ] && swww img "$WALLPAPER" --transition-type none 2>>"$LOG" &

    notify-send -a "Monitor" "Toggle Monitor" "Modo EXTENDIDO" -t 2000 -i display

elif [ -z "$SECONDARY_DETECTED" ]; then
    # Solo un monitor y no estaba en mirror → nada que hacer
    notify-send -a "Monitor" "Toggle Monitor" "Solo monitor principal conectado" -t 2000

elif [ "$STATE_MODE" = "mirrored" ] && [ -n "$SECONDARY_DETECTED" ]; then
    # ═══ ESPEJO → EXTENDIDO (secundario visible, posible mirror roto) ═══
    if [ -f "$STATE" ]; then
        SEC_CFG=$(grep "^monitor=" "$STATE" | head -1 | sed 's/^monitor=//')
        echo "restoring saved: $SEC_CFG" >> "$LOG"
        [ -n "$SEC_CFG" ] && hyprctl keyword monitor "$SEC_CFG" 2>>"$LOG"
    fi
    echo "extended" > "$STATE"
    notify-send -a "Monitor" "Toggle Monitor" "Modo EXTENDIDO" -t 2000 -i display

else
    # ═══ EXTENDIDO → ESPEJO ═══
    # Guardar config del secundario
    SEC_LINE=$(hyprctl monitors 2>>"$LOG" | grep -A1 "^Monitor $SEC " | tail -1)
    echo "saving: $SEC_LINE" >> "$LOG"

    SEC_RES=$(echo "$SEC_LINE" | grep -oE '[0-9]+x[0-9]+@[0-9.]+' | head -1)
    [ -z "$SEC_RES" ] && SEC_RES="1680x1050@60"

    echo "mirrored" > "$STATE"
    echo "monitor=$SEC,$SEC_RES,0x0,1,transform,1" >> "$STATE"

    hyprctl keyword monitor "$SEC,preferred,auto,1,mirror,$MAIN" 2>>"$LOG"
    notify-send -a "Monitor" "Toggle Monitor" "Modo ESPEJO — secundario duplica al principal" -t 2000 -i display
fi
