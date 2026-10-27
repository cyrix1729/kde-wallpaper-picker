#!/usr/bin/python3 -I
"""Builds the "sphinx-ascii" Plymouth boot theme into ./sphinx-ascii (install with install.sh)."""
import os
import shutil
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QFont, QFontMetrics, QGuiApplication, QImage, QPainter

OUT = Path(__file__).resolve().parent / "sphinx-ascii"
SPINNER = Path("/usr/share/plymouth/themes/spinner")
ACCENT = QColor(233, 100, 58)
SHADOW = QColor(110, 60, 45)
DIM = QColor(120, 120, 120)

BANNER = r"""
███████╗██████╗ ██╗  ██╗██╗███╗   ██╗██╗  ██╗
██╔════╝██╔══██╗██║  ██║██║████╗  ██║╚██╗██╔╝
███████╗██████╔╝███████║██║██╔██╗ ██║ ╚███╔╝
╚════██║██╔═══╝ ██╔══██║██║██║╚██╗██║ ██╔██╗
███████║██║     ██║  ██║██║██║ ╚████║██╔╝ ██╗
╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
""".strip("\n").splitlines()
SUBTITLE = "> waking up fedora_"


def render(lines, size, colour_for):
    font = QFont("Hack", size)
    fm = QFontMetrics(font)
    w = max(fm.horizontalAdvance(l) for l in lines) + 4
    h = fm.lineSpacing() * len(lines) + 4
    img = QImage(w, h, QImage.Format_ARGB32)
    img.fill(Qt.transparent)
    p = QPainter(img)
    p.setFont(font)
    for row, line in enumerate(lines):
        y = 2 + fm.ascent() + row * fm.lineSpacing()
        for col, ch in enumerate(line):
            if ch != " ":
                p.setPen(colour_for(ch))
                p.drawText(2 + col * fm.horizontalAdvance("█"), y, ch)
    p.end()
    return img


def main():
    QGuiApplication([])
    shutil.rmtree(OUT, ignore_errors=True)
    OUT.mkdir()
    for f in ["bullet.png", "capslock.png", "entry.png", "keyboard.png", "keymap-render.png", "lock.png"]:
        shutil.copy(SPINNER / f, OUT / f)

    art = BANNER + ["", SUBTITLE.center(len(BANNER[0]))]
    render(art, 20, lambda ch: ACCENT if ch == "█" else DIM if ch.isascii() else SHADOW).save(str(OUT / "watermark.png"))

    width = 16
    for i in range(2 * (width - 3)):
        pos = i if i < width - 3 else 2 * (width - 3) - i
        bar = "[" + " " * pos + "<=>" + " " * (width - 3 - pos) + "]"
        render([bar], 14, lambda ch: ACCENT if ch in "<=>" else DIM).save(str(OUT / f"throbber-{i + 1:04d}.png"))

    (OUT / "sphinx-ascii.plymouth").write_text(
        (SPINNER / "spinner.plymouth").read_text()
        .split("[two-step]")[1]
        .replace("ImageDir=/usr/share/plymouth/themes//spinner", "ImageDir=/usr/share/plymouth/themes/sphinx-ascii")
        .replace("Font=Cantarell 12", "Font=Hack 12")
        .replace("TitleFont=Cantarell Light 30", "TitleFont=Hack 24")
        .replace("WatermarkVerticalAlignment=.96", "WatermarkVerticalAlignment=.42")
        .replace("VerticalAlignment=.7\n", "VerticalAlignment=.62\n")
        .replace("ProgressBarForegroundColor=0xffffff", "ProgressBarForegroundColor=0x%06x" % (ACCENT.rgb() & 0xffffff))
        .join(["[Plymouth Theme]\nName=Sphinx ASCII\nDescription=ASCII-art boot splash\nModuleName=two-step\n\n[two-step]", ""])
    )


if __name__ == "__main__":
    main()
