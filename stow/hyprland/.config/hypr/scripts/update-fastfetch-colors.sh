#!/bin/bash

KITTY_THEME="$HOME/.config/kitty/theme.conf"
FASTFETCH_CONFIG="$HOME/.config/fastfetch/config.jsonc"
HYDE_CONF="$HOME/.config/hyde/hyde.conf"

CURRENT_THEME=$(grep "^hydeTheme=" "$HYDE_CONF" 2>/dev/null | cut -d'"' -f2)

if [ "$CURRENT_THEME" = "OLED Mono" ]; then
    PRIMARY="#999999"
    SECONDARY="#777777"
    TERTIARY="#555555"
else
    if [ ! -f "$KITTY_THEME" ]; then
        echo "Error: $KITTY_THEME not found"
        exit 1
    fi
    PRIMARY=$(grep "^color2" "$KITTY_THEME" | awk '{print $2}')
    SECONDARY=$(grep "^color4" "$KITTY_THEME" | awk '{print $2}')
    TERTIARY=$(grep "^color3" "$KITTY_THEME" | awk '{print $2}')
fi

cat > "$FASTFETCH_CONFIG" << EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "\$(find \"\$HOME/terminalphoto/\" -name \"*.png\" | shuf -n 1)",
    "type": "kitty-direct",
    "width": 30,
    "height": 15
  },
  "display": {
    "separator": " : ",
    "color": "#ffffff"
  },
  "modules": [
    {
      "type": "custom",
      "format": "\\u001b[32m   󰄛  コンピューター"
    },
    {
      "type": "custom",
      "format": "\\u001b[90m┌──────────────────────────────────────────┐"
    },
    {
      "type": "os",
      "key": "  󰣇 OS",
      "format": "{2}",
      "keyColor": "$PRIMARY"
    },
    {
      "type": "kernel",
      "key": "   Kernel",
      "format": "{2}",
      "keyColor": "$PRIMARY"
    },
    {
      "type": "packages",
      "key": "  󰏗 Packages",
      "keyColor": "$SECONDARY"
    },
    {
      "type": "display",
      "key": "  󰍹 Display",
      "format": "{1}x{2} @ {3}Hz [{7}]",
      "keyColor": "$SECONDARY"
    },
    {
      "type": "terminal",
      "key": "  >_ Terminal",
      "keyColor": "$TERTIARY"
    },
    {
      "type": "wm",
      "key": "  󱗃 WM",
      "format": "{2}",
      "keyColor": "$TERTIARY"
    },
    {
      "type": "custom",
      "format": "\\u001b[90m└──────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "title",
      "key": "  ",
      "format": "{6} {7} {8}"
    },
    {
      "type": "custom",
      "format": "\\u001b[90m┌──────────────────────────────────────────┐"
    },
    {
      "type": "cpu",
      "format": "{1} @ {7}",
      "key": "  CPU",
      "keyColor": "$PRIMARY"
    },
    {
      "type": "gpu",
      "format": "{1} {2}",
      "key": "  󰊴 GPU",
      "keyColor": "$PRIMARY"
    },
    {
      "type": "gpu",
      "format": "{3}",
      "key": "  GPU Driver",
      "keyColor": "$SECONDARY"
    },
    {
      "type": "memory",
      "key": "  Memory",
      "keyColor": "$SECONDARY"
    },
    {
      "type": "command",
      "key": "  󱦟 OS Age ",
      "keyColor": "$TERTIARY",
      "text": "birth_install=\$(stat -c %W /); current=\$(date +%s); time_progression=\$((current - birth_install)); days_difference=\$((time_progression / 86400)); echo \$days_difference days"
    },
    {
      "type": "uptime",
      "key": "  󱫐 Uptime ",
      "keyColor": "$TERTIARY"
    },
    {
      "type": "custom",
      "format": "\\u001b[90m└──────────────────────────────────────────┘"
    },
    {
      "type": "colors",
      "paddingLeft": 2,
      "symbol": "circle"
    },
    "break"
  ]
}
EOF

echo "Fastfetch config updated with colors from $KITTY_THEME"
echo "Primary: $PRIMARY"
echo "Secondary: $SECONDARY"
echo "Tertiary: $TERTIARY"
