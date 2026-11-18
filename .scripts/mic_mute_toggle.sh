#!/bin/bash
# Mic-mute key (F4): mute every mic, or unmute them all, flipping whatever the default mic is now.
# Run by XF86AudioMicMute in the i3 config.
#
# The F4 LED only follows the laptop's built-in mic. Muting just the default mic left the LED
# off when a USB or Bluetooth mic was the default, and left the built-in mic live.

if [ "$(LC_ALL=C pactl get-source-mute @DEFAULT_SOURCE@)" = "Mute: yes" ]; then mute=0; else mute=1; fi

# Every source except the monitors of outputs
LC_ALL=C pactl list short sources | awk '$2 !~ /\.monitor$/ { print $2 }' | while read -r source; do
    pactl set-source-mute "$source" "$mute"
done
