#!/bin/bash
# Matugen post-hook for waybar
# If OLED Mono theme is active, restore fixed OLED Mono colors before reloading
# Otherwise, just reload waybar normally

HYDE_CONF="$HOME/.config/hyde/hyde.conf"
CURRENT_THEME=$(grep '^hydeTheme=' "$HYDE_CONF" 2>/dev/null | cut -d'"' -f2)

if [ "$CURRENT_THEME" = "OLED Mono" ]; then
    # Restore OLED Mono fixed colors to theme.css
    cat > "$HOME/.config/waybar/theme.css" << 'EOF'
@define-color bar-bg transparent;
@define-color main-bg #000000;
@define-color main-fg #ffffff;
@define-color wb-act-bg #ffffff;
@define-color wb-act-fg #000000;
@define-color wb-hvr-bg #333333;
@define-color wb-hvr-fg #ffffff;
EOF
fi

# Reload waybar
pkill -SIGUSR2 waybar
