#!/bin/bash
# Plays the music for the current wallpaper (see wallpaper-picker), falling back to SomaFM Drone Zone.
# --now skips the startup delay (used when the picker switches tracks).
[ "$1" = "--now" ] || sleep 5  # let audio and the network come up
SRC="$("$HOME/.local/bin/wallpaper-picker" --music-source 2>/dev/null)"
[ -n "$SRC" ] || SRC=https://ice1.somafm.com/dronezone-128-mp3
mkdir -p "$HOME/.cache/wallpaper-picker"
printf '%s' "$SRC" > "$HOME/.cache/wallpaper-picker/music-source"
if [ -d "$SRC" ]; then
    exec cvlc --control dbus --random --loop --gain 0.6 "$SRC"
else
    exec cvlc --control dbus --loop --gain 0.6 "$SRC"
fi
