#!/bin/bash

IFS=$'\n\t'

waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
msg='Choose Waybar Style'

menu() {
    options=()
    while IFS= read -r file; do
        if [ -f "$waybar_styles/$file" ]; then
            options+=("$(basename "$file" .css)")
        fi
    done < <(find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' -exec basename {} \; | sort)
    
    printf '%s\n' "${options[@]}"
}

apply_style() {
    ln -sf "$waybar_styles/$1.css" "$waybar_style"
    "${SCRIPTSDIR}/wbrestart.sh" &
}

main() {
    choice=$(menu | rofi -i -dmenu -mesg "$msg")

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    apply_style "$choice"
}

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

main
