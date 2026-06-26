#!/bin/bash

exec >> /tmp/wallpaper-cycle.log 2>&1
echo "=== $(date) ==="

WALLPAPER_DIR="$HOME/Wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
MATUGEN_CACHE="$HOME/.cache/wallpapers/matugen_temp"

MATUGEN=$(command -v matugen 2>/dev/null)
if [ -z "$MATUGEN" ]; then
    notify-send "Error" "matugen not found in PATH" 2>/dev/null
    exit 1
fi

mkdir -p "$MATUGEN_CACHE"

shopt -s nullglob
wallList=("$WALLPAPER_DIR"/*.gif "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.jpeg)
shopt -u nullglob

[ ${#wallList[@]} -eq 0 ] && exit 1

IFS=$'\n'
wallList=($(printf '%s\n' "${wallList[@]}" | sort -r))

currentWall="$(readlink -f "$SYMLINK_PATH" 2>/dev/null)"
currentIndex=-1
for i in "${!wallList[@]}"; do
    if [ "$(readlink -f "${wallList[$i]}")" = "$currentWall" ]; then
        currentIndex=$i
        break
    fi
done

case "$1" in
    n|next)
        if [ $currentIndex -eq -1 ]; then
            nextIndex=0
        else
            nextIndex=$(( (currentIndex + 1) % ${#wallList[@]} ))
        fi
        ;;
    p|prev)
        if [ $currentIndex -eq -1 ] || [ $currentIndex -eq 0 ]; then
            nextIndex=$(( ${#wallList[@]} - 1 ))
        else
            nextIndex=$(( currentIndex - 1 ))
        fi
        ;;
    *)
        echo "Usage: $0 {n|next|p|prev}"
        exit 1
        ;;
esac

SELECTED_PATH="${wallList[$nextIndex]}"
SELECTED_NAME="$(basename "$SELECTED_PATH")"

ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

swww query &>/dev/null
if [ $? -ne 0 ]; then
    swww-daemon --format xrgb &
    sleep 1
fi

# ── Wallpaper principal (DP-1): animado ──
swww img "$SELECTED_PATH" --outputs DP-1 --resize crop --transition-type any --transition-fps 60 --transition-duration 0.5 --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" &

# ── Wallpaper vertical (HDMI-A-1): animado optimizado (filter rápido) ──
swww img "$SELECTED_PATH" --outputs HDMI-A-1 --resize crop --filter Nearest --transition-type none 2>/dev/null &

HYPLOCK_WALL="$HOME/.config/hypr/hyprlock_wallpaper.png"

if [[ "$SELECTED_NAME" == *.gif ]]; then
    TEMP_PNG="$MATUGEN_CACHE/${SELECTED_NAME%.*}.png"
    if [ ! -f "$TEMP_PNG" ] || [ "$SELECTED_PATH" -nt "$TEMP_PNG" ]; then
        magick "$SELECTED_PATH[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null || convert "$SELECTED_PATH[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null
    fi
    cp "$TEMP_PNG" "$HYPLOCK_WALL"
    "$MATUGEN" image "$TEMP_PNG"
else
    cp "$SELECTED_PATH" "$HYPLOCK_WALL"
    "$MATUGEN" image "$SELECTED_PATH"
fi

notify-send "Wallpaper" "$SELECTED_NAME" 2>/dev/null
