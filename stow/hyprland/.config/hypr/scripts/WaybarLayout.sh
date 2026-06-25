#!/bin/bash

IFS=$'\n\t'

waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
msg='Choose Waybar Layout'

menu() {
    options=()
    while IFS= read -r file; do
        options+=("$(basename "$file")")
    done < <(find -L "$waybar_layouts" -maxdepth 1 -type f -exec basename {} \; | sort)

    printf '%s\n' "${options[@]}"
}

apply_config() {
    ln -sf "$waybar_layouts/$1" "$waybar_config"
    "${SCRIPTSDIR}/wbrestart.sh" &
}

main() {
    choice=$(menu | rofi -i -dmenu -mesg "$msg")

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    case $choice in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

main
