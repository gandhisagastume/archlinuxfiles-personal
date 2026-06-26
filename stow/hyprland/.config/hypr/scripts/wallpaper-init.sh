#!/bin/bash

SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
MATUGEN_CACHE="$HOME/.cache/wallpapers/matugen_temp"
VERT_CACHE="$HOME/.cache/wallpapers/vertical"

MATUGEN=$(command -v matugen 2>/dev/null)

mkdir -p "$MATUGEN_CACHE" "$VERT_CACHE"

swww query &>/dev/null
if [ $? -ne 0 ]; then
    swww-daemon --format xrgb &
    sleep 1
fi

HYPLOCK_WALL="$HOME/.config/hypr/hyprlock_wallpaper.png"

# ── Función: generar y setear wallpaper vertical estático ──
set_vertical_wall() {
    local WALL="$1"
    local WALL_NAME="$(basename "$WALL")"
    local VERT_PNG="$VERT_CACHE/${WALL_NAME%.*}_vert.png"

    if [[ "$WALL_NAME" == *.gif ]]; then
        if [ ! -f "$VERT_PNG" ] || [ "$WALL" -nt "$VERT_PNG" ]; then
            magick "$WALL[0]" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null || convert "$WALL[0]" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null
        fi
    elif [[ "$WALL_NAME" == *.png ]] || [[ "$WALL_NAME" == *.jpg ]] || [[ "$WALL_NAME" == *.jpeg ]]; then
        if [ ! -f "$VERT_PNG" ] || [ "$WALL" -nt "$VERT_PNG" ]; then
            magick "$WALL" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null || convert "$WALL" -resize x1680 -gravity east -crop 1050x1680+0+0 +repage -depth 8 "$VERT_PNG" 2>/dev/null
        fi
    fi
    [ -f "$VERT_PNG" ] && swww img "$VERT_PNG" --outputs HDMI-A-1 --resize crop --transition-type none 2>/dev/null &
}

if [ -L "$SYMLINK_PATH" ] && [ -e "$SYMLINK_PATH" ]; then
    WALL="$(readlink -f "$SYMLINK_PATH")"
    WALL_NAME="$(basename "$WALL")"
    swww img "$WALL" --outputs DP-1 --resize crop --transition-type grow --transition-duration 0.5 --transition-fps 60 --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" &
    set_vertical_wall "$WALL"
    if [ -n "$MATUGEN" ]; then
        if [[ "$WALL_NAME" == *.gif ]]; then
            TEMP_PNG="$MATUGEN_CACHE/${WALL_NAME%.*}.png"
            if [ ! -f "$TEMP_PNG" ] || [ "$WALL" -nt "$TEMP_PNG" ]; then
                magick "$WALL[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null || convert "$WALL[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null
            fi
            cp "$TEMP_PNG" "$HYPLOCK_WALL"
            "$MATUGEN" image "$TEMP_PNG"
        else
            cp "$WALL" "$HYPLOCK_WALL"
            "$MATUGEN" image "$WALL"
        fi
    fi
else
    WALLPAPER_DIR="$HOME/Wallpapers"
    shopt -s nullglob
    FIRST_WALL=$(ls -t "$WALLPAPER_DIR"/*.gif "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.jpeg 2>/dev/null | head -1)
    shopt -u nullglob
    if [ -n "$FIRST_WALL" ]; then
        WALL_NAME="$(basename "$FIRST_WALL")"
        ln -sf "$FIRST_WALL" "$SYMLINK_PATH"
        swww img "$FIRST_WALL" --outputs DP-1 --resize crop --transition-type grow --transition-duration 0.5 --transition-fps 60 --invert-y &
        set_vertical_wall "$FIRST_WALL"
        if [ -n "$MATUGEN" ]; then
            if [[ "$WALL_NAME" == *.gif ]]; then
                TEMP_PNG="$MATUGEN_CACHE/${WALL_NAME%.*}.png"
                if [ ! -f "$TEMP_PNG" ] || [ "$FIRST_WALL" -nt "$TEMP_PNG" ]; then
                    magick "$FIRST_WALL[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null || convert "$FIRST_WALL[0]" -depth 8 -type TrueColor "$TEMP_PNG" 2>/dev/null
                fi
                cp "$TEMP_PNG" "$HYPLOCK_WALL"
                "$MATUGEN" image "$TEMP_PNG"
            else
                cp "$FIRST_WALL" "$HYPLOCK_WALL"
                "$MATUGEN" image "$FIRST_WALL"
            fi
        fi
    fi
fi
