#!/bin/bash
# Links this checkout into ~/.local so edits here take effect immediately.
# Existing files are moved aside with a .bak suffix.
# --smart also installs smart mode (CLIP image recognition for picking music).
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

if [ "$1" = "--smart" ]; then
    # Smart mode: CLIP in its own environment (~200 MB), plus the model (~600 MB) on first use.
    VENV="$HOME/.local/share/wallpaper-picker-smart/venv"
    echo "Setting up smart mode in $VENV..."
    if command -v uv >/dev/null; then
        uv venv -q --python 3.12 "$VENV"
        VIRTUAL_ENV="$VENV" uv pip install -q fastembed
    else
        python3 -m venv "$VENV"
        "$VENV/bin/pip" install -q fastembed
    fi
    python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".config/wallpaper-picker/themes.json"
p.parent.mkdir(parents=True, exist_ok=True)
d = json.loads(p.read_text()) if p.exists() else {}
d["mode"] = "smart"
p.write_text(json.dumps(d, indent=2) + "\n")
PY
    echo "Downloading the model and analysing your wallpapers..."
    "$REPO/wallpaper-picker" --analyse
fi

echo "Installed. Add wallpapers to ~/Pictures/Wallpapers and bind a shortcut to"
echo "\"Wallpaper Picker\" in System Settings > Keyboard > Shortcuts."
