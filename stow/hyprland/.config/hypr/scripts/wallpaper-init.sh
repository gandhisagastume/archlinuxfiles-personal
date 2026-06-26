#!/bin/bash

SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
MATUGEN_CACHE="$HOME/.cache/wallpapers/matugen_temp"

MATUGEN=$(command -v matugen 2>/dev/null)

mkdir -p "$MATUGEN_CACHE"

swww query &>/dev/null
if [ $? -ne 0 ]; then
    swww-daemon --format xrgb &
    sleep 1
fi

HYPLOCK_WALL="$HOME/.config/hypr/hyprlock_wallpaper.png"

if [ -L "$SYMLINK_PATH" ] && [ -e "$SYMLINK_PATH" ]; then
    WALL="$(readlink -f "$SYMLINK_PATH")"
    WALL_NAME="$(basename "$WALL")"
    swww img "$WALL" --resize crop --crop-gravity right --transition-type grow --transition-duration 0.5 --transition-fps 60 --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo '0,0')" &
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
        swww img "$FIRST_WALL" --resize crop --crop-gravity right --transition-type grow --transition-duration 0.5 --transition-fps 60 --invert-y &
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
