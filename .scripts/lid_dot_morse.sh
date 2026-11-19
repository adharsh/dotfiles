#!/bin/bash
# The red dot on the lid's ThinkPad logo spells adhar.sh in Morse, over and over, timed like the
# site's own icon (morseFrames in adhar.sh's layout.mjs): lit for 8 units, off for 4, then the word,
# a dot lasting a unit and a dash three, with a unit between marks, three between letters and
# seven after the word. Between rounds it rests lit, as the dot normally is.
#
# Run by the lid-dot-morse user service. Needs no sudo: brightnessctl's udev rule lets the input
# group write LEDs. While the laptop sleeps this is frozen, and the firmware decides what the dot does.
# Stopped, it leaves the dot lit.

led=/sys/class/leds/tpacpi::lid_logo_dot/brightness
unit_ms=200
code=".- -.. .... .- .-. .-.-.- ... ...."  # a d h a r . s h

# show on|off UNITS
show() {
    if [ "$1" = on ]; then echo 255 >"$led"; else echo 0 >"$led"; fi
    local ms=$(($2 * unit_ms))
    sleep "$((ms / 1000)).$(printf %03d $((ms % 1000)))"
}

trap 'echo 255 >"$led"; exit 0' TERM INT

read -ra letters <<<"$code"
while true; do
    show on 8
    show off 4
    for i in "${!letters[@]}"; do
        letter=${letters[i]}
        for ((j = 0; j < ${#letter}; j++)); do
            if [ "${letter:j:1}" = . ]; then show on 1; else show on 3; fi
            if ((j < ${#letter} - 1)); then gap=1; elif ((i < ${#letters[@]} - 1)); then gap=3; else gap=7; fi
            show off $gap
        done
    done
done
