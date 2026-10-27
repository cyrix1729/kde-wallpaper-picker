#!/bin/bash
# Links this checkout into ~/.local so edits here take effect immediately.
# Existing files are moved aside with a .bak suffix.
set -e
REPO="$(cd "$(dirname "$0")" && pwd)"

link() {  # link <target in repo> <path to create>
    mkdir -p "$(dirname "$2")"
    if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.bak"; fi
    ln -sfn "$1" "$2"
}

link "$REPO/wallpaper-picker" "$HOME/.local/bin/wallpaper-picker"
link "$REPO/boot-music.sh" "$HOME/.local/bin/boot-music.sh"
link "$REPO" "$HOME/.local/share/wallpaper-picker"
link "$REPO/plymouth" "$HOME/.local/share/plymouth-sphinx"

mkdir -p "$HOME/.local/share/applications" "$HOME/.config/autostart" "$HOME/Pictures/Wallpapers"
sed "s|@HOME@|$HOME|g" "$REPO/wallpaper-picker.desktop" > "$HOME/.local/share/applications/wallpaper-picker.desktop"
sed "s|@HOME@|$HOME|g" "$REPO/boot-music.desktop" > "$HOME/.config/autostart/boot-music.desktop"

echo "Installed. Add wallpapers to ~/Pictures/Wallpapers and bind a shortcut to"
echo "\"Wallpaper Picker\" in System Settings > Keyboard > Shortcuts."
