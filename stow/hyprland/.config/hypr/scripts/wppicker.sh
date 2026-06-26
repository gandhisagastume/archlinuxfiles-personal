#!/bin/bash

exec >> /tmp/wppicker.log 2>&1
echo "=== $(date) ==="

WALLPAPER_DIR="$HOME/Wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
CACHE_DIR="$HOME/.cache/wallpapers"
MATUGEN_CACHE="$HOME/.cache/wallpapers/matugen_temp"

MATUGEN=$(command -v matugen 2>/dev/null)
if [ -z "$MATUGEN" ]; then
    notify-send "Error" "matugen not found in PATH" 2>/dev/null
    exit 1
fi

mkdir -p "$CACHE_DIR" "$MATUGEN_CACHE"

cd "$WALLPAPER_DIR" || exit 1

shopt -s nullglob

for f in *.gif *.jpg *.jpeg *.png; do
    thumb="$CACHE_DIR/${f%.*}.png"
    if [ ! -f "$thumb" ] || [ "$f" -nt "$thumb" ]; then
        if [[ "$f" == *.gif ]]; then
            magick "$f[0]" -resize 400x225 "$thumb" 2>/dev/null || convert "$f[0]" -resize 400x225 "$thumb" 2>/dev/null
        else
            magick "$f" -resize 400x225 "$thumb" 2>/dev/null || convert "$f" -resize 400x225 "$thumb" 2>/dev/null
        fi
    fi
done

SELECTED_WALL=$(for a in $(ls -t *.jpg *.png *.gif *.jpeg); do
    thumb="$CACHE_DIR/${a%.*}.png"
    if [ -f "$thumb" ]; then
        echo -en "$a\0icon\x1f$thumb\n"
    else
        echo -en "$a\0icon\x1f$a\n"
    fi
done | rofi -dmenu -p "Wallpapers")

[ -z "$SELECTED_WALL" ] && exit 1
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

swww query &>/dev/null
if [ $? -ne 0 ]; then
    swww-daemon --format xrgb &
    sleep 1
fi

# ── Wallpaper principal (DP-1): animado ──
swww img "$SELECTED_PATH" --outputs DP-1 --resize crop --transition-type any --transition-fps 60 --transition-duration 0.5 --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" &

# ── Wallpaper vertical (HDMI-A-1): estático pre-recortado ──
VERT_CACHE="$HOME/.cache/wallpapers/vertical"
mkdir -p "$VERT_CACHE"
VERT_PNG="$VERT_CACHE/${SELECTED_WALL%.*}_vert.png"
if [[ "$SELECTED_WALL" == *.gif ]]; then
    if [ ! -f "$VERT_PNG" ] || [ "$SELECTED_PATH" -nt "$VERT_PNG" ]; then
        magick "$SELECTED_PATH[0]" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null || convert "$SELECTED_PATH[0]" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null
    fi
elif [[ "$SELECTED_WALL" == *.png ]] || [[ "$SELECTED_WALL" == *.jpg ]] || [[ "$SELECTED_WALL" == *.jpeg ]]; then
    if [ ! -f "$VERT_PNG" ] || [ "$SELECTED_PATH" -nt "$VERT_PNG" ]; then
        magick "$SELECTED_PATH" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null || convert "$SELECTED_PATH" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null
    fi
fi
[ -f "$VERT_PNG" ] && swww img "$VERT_PNG" --outputs HDMI-A-1 --resize crop --transition-type none 2>/dev/null &

HYPLOCK_WALL="$HOME/.config/hypr/hyprlock_wallpaper.png"

if [[ "$SELECTED_WALL" == *.gif ]]; then
    TEMP_PNG="$MATUGEN_CACHE/${SELECTED_WALL%.*}.png"
    if [ ! -f "$TEMP_PNG" ] || [ "$SELECTED_PATH" -nt "$TEMP_PNG" ]; then
        magick "$SELECTED_PATH[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null || convert "$SELECTED_PATH[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null
    fi
    cp "$TEMP_PNG" "$HYPLOCK_WALL"
    "$MATUGEN" image "$TEMP_PNG"
else
    cp "$SELECTED_PATH" "$HYPLOCK_WALL"
    "$MATUGEN" image "$SELECTED_PATH"
fi

notify-send -i "$CACHE_DIR/${SELECTED_WALL%.*}.png" "Wallpaper" "$SELECTED_WALL" 2>/dev/null
