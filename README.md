# Wallpaper Picker and music changer

A full-screen cover-flow wallpaper picker for KDE Plasma plays music to match wallpaper, based on color profile of image. Applying a wallpaper also sets:

- the **lock screen** to the same image
- the **accent colour** to the image's main vivid colour
- the **music** to an internet radio station that matches the image's mood

## Install

```bash
git clone https://github.com/cyrix1729/kde-wallpaper-picker ~/dev/kde-wallpaper-picker
~/dev/kde-wallpaper-picker/install.sh
```

`install.sh` symlinks the checkout into `~/.local`, so edits in the repo take effect right away.
It also adds the app-menu entry and the login music autostart. Then bind a shortcut to
"Wallpaper Picker" in System Settings → Keyboard → Shortcuts (here it's Meta+Shift+W).

Needs Plasma 6, PySide6 (`sudo dnf install python3-pyside6`) and VLC (`sudo dnf install vlc`).

## Usage

Open it with **Meta+Shift+W**, or launch "Wallpaper Picker" from the app menu, or run `wallpaper-picker` in a terminal.

To add wallpapers, drop images (jpg, png, webp, gif, bmp, avif, jxl) into `~/Pictures/Wallpapers`,
or set `"folder"` in `themes.json` (see below) to use another folder. They're picked up the next
time the picker opens. Nothing else needs to run.

To use a different folder once: `wallpaper-picker ~/some/other/folder`.

### Commands

| Command                          | What it does                                              |
|----------------------------------|-----------------------------------------------------------|
| `wallpaper-picker`               | Open the picker                                           |
| `wallpaper-picker --moods`       | List the mood picked for every wallpaper                  |
| `wallpaper-picker --music-source`| Print what music the current wallpaper plays              |

## How it works

### Accent colour

The image is shrunk to 64×64 and its pixels are grouped by hue, ignoring greys and very
dark pixels. The biggest group, weighted by how vivid it is, wins. Its colour is brightened
and saturated a little so it reads well as an accent, then applied with
`plasma-apply-colorscheme --accent-color`. Anything using the theme highlight colour, like the
Performance Grid widget, follows it. Mostly grey images keep the current accent.

### Music mood

The same thumbnail is used to pick a mood from its brightness, colourfulness, main hue and
how many neon or bright-light pixels it has:

| Mood     | Looks like                          | Station (SomaFM)     |
|----------|-------------------------------------|----------------------|
| `warm`   | orange / red / gold                 | Fluid (lofi-ish)     |
| `city`   | dark with neon or bright lights     | Vaporwaves           |
| `space`  | dark blue / purple / magenta        | Deep Space One       |
| `nature` | green, including dark forests       | Groove Salad Classic |
| `dark`   | dark, any other colour              | Dark Zone            |
| `cool`   | blue / cyan                         | Groove Salad         |
| `dreamy` | pastel or pink                      | Lush                 |
| `muted`  | grey / colourless                   | Drone Zone           |

The mood is worked out fresh each time it's needed and never cached:

- **When you apply a wallpaper** in the picker. A new image gets its mood the first time you pick it.
- **At login.** `boot-music.sh` asks the picker which music goes with the current wallpaper.

When the music changes, the picker restarts the player. If the source is the same it leaves
the music alone, and if you stopped the music it stays off. Setting a wallpaper through KDE's
own settings won't change the music until the next login.

### Where the music comes from

The first match wins:

1. a `music` entry for that wallpaper in `themes.json`
2. songs in `~/Music/Wallpapers/<wallpaper name without extension>/`
3. songs in `~/Music/Moods/<mood>/`
4. the mood's radio station

The `~/Music/Moods/*` folders start empty, so by default it's all radio.
Radio plays indefinitely. Folders are shuffled and looped.

## Customising: `~/.config/wallpaper-picker/themes.json`

The file is created with the defaults on first run. Entries are keyed by wallpaper file name:

```json
{
  "folder": "~/Desktop/wallpapers",
  "default": { "accent": "auto" },
  "moods": {
    "warm": "https://ice1.somafm.com/fluid-128-mp3",
    "...": "..."
  },
  "Autumn.jpg":  { "accent": "#e9643a" },
  "Kokkini.png": { "mood": "city" },
  "Path.jpg":    { "music": "https://ice1.somafm.com/groovesalad-128-mp3" }
}
```

- `folder`: where wallpapers are listed from (default `~/Pictures/Wallpapers`)
- `accent`: `"auto" (from the image) or any colour like `"#e9643a"`
- `mood`: force one of the moods above instead of guessing
- `music`: a stream URL, an audio file, or a folder
- `moods`: change which station a mood plays (other SomaFM stations are listed at somafm.com)

Changes take effect the next time you apply a wallpaper.

## Files

| Path                                                   | Purpose                                        |
|--------------------------------------------------------|------------------------------------------------|
| `~/.local/bin/wallpaper-picker`                        | Python backend: apply, accent, mood, music     |
| `~/.local/share/wallpaper-picker/picker.qml`           | The cover-flow UI                              |
| `~/.local/share/applications/wallpaper-picker.desktop` | App-menu entry (bind your shortcut to it)      |
| `~/.local/bin/boot-music.sh`                           | Plays the music (at login and on switches)     |
| `~/.config/autostart/` (Boot Music entry)              | Runs `boot-music.sh` at login                  |
| `~/.config/wallpaper-picker/themes.json`               | Your overrides                                 |
| `~/.cache/wallpaper-picker/music-source`               | What's playing now, so it isn't restarted      |
| `~/Pictures/Wallpapers/` (or `folder`)                 | Wallpaper images                               |
| `~/Music/Moods/<mood>/`, `~/Music/Wallpapers/<name>/`  | Optional local music                           |

The installed paths are symlinks into this repo, except the two `.desktop` files, which `install.sh`
generates from the templates here.

## Boot splash (separate)

An ASCII-art boot screen theme, `sphinx-ascii`, lives in `~/.local/share/plymouth-sphinx/`.
It isn't linked to the picker, and its orange colour is fixed when it's built.

- Install: `sudo ~/.local/share/plymouth-sphinx/install.sh`
- Change the art or text: edit `build-theme.py`, run it, then install again
- Undo: `sudo plymouth-set-default-theme bgrt -R`
