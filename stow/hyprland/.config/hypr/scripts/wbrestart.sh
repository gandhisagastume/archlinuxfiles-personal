#!/bin/bash
pkill -x waybar 2>/dev/null
sleep 0.5
waybar &
