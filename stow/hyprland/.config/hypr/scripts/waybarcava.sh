#!/bin/bash

is_cava_ServerExist=$(pgrep -c "cava")
if [ "$is_cava_ServerExist" = 0 ]; then
    exit
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

config_file="/tmp/bar_cava_config"
cat >"$config_file" <<EOF
[general]
bars = 12
framerate = 60
sensitivity = 120
[input]
method = pulse
[output]
channels = stereo
method = raw
raw_target = /tmp/bar_cava
data_format = ascii
ascii_max_range = 7
[smoothing]
monstercat = 1
waves = 0
noise_reduction = 0.65
[color]
gradient = 1
gradient_color_1 = '#8bd5ca'
gradient_color_2 = '#a6da95'
gradient_color_3 = '#eed49f'
gradient_color_4 = '#f5a97f'
gradient_color_5 = '#ee99a0'
gradient_color_6 = '#b7bdf8'
EOF

cava -p "$config_file" >/tmp/bar_cava &

while true; do
    sleep 0.1
    cava_output=$(cat /tmp/bar_cava 2>/dev/null)
    if [ -n "$cava_output" ]; then
        echo "$cava_output"
    fi
done
