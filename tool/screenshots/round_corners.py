"""Turns the raw screenshots into the README images.

For each tool/screenshots/out/<theme>-<screen>.png (1170 x 2532):
  1. shrink it to 585 px wide (sharp on high-DPI screens, small file),
  2. give it smooth rounded corners (transparent outside, anti-aliased),
  3. draw a thin border in the theme's border color, so the screenshot's
     edge stays visible on GitHub's white and dark backgrounds.
Saves to docs/screenshots/<theme>-<screen>.png.

Run from the project folder:  python tool/screenshots/round_corners.py
Needs Pillow:                 pip install pillow
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tool" / "screenshots" / "out"
DST = ROOT / "docs" / "screenshots"

WIDTH = 585  # output width in pixels (390 dp at 1.5x)
RADIUS = 0.105  # corner radius, as a share of the width (like a phone screen)
BORDER = 2  # border width in output pixels
BORDER_COLOR = {"dark": (35, 40, 49), "light": (227, 231, 236)}  # the app's border tokens
SS = 4  # draw masks 4x bigger, then shrink: smooth, anti-aliased edges


def rounded_mask(size, radius, inset=0):
    """A white rounded rectangle on black, drawn big and shrunk for smoothness."""
    w, h = size
    big = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (inset * SS, inset * SS, (w - inset) * SS - 1, (h - inset) * SS - 1),
        radius=(radius - inset) * SS,
        fill=255,
    )
    return big.resize(size, Image.LANCZOS)


def main():
    DST.mkdir(parents=True, exist_ok=True)
    for src in sorted(SRC.glob("*.png")):
        theme = src.stem.split("-")[0]
        shot = Image.open(src).convert("RGB")
        height = round(shot.height * WIDTH / shot.width)
        shot = shot.resize((WIDTH, height), Image.LANCZOS)
        radius = round(WIDTH * RADIUS)

        outer = rounded_mask(shot.size, radius)  # the whole rounded shape
        inner = rounded_mask(shot.size, radius, inset=BORDER)  # inside the border

        # Start with the border color, then put the screenshot inside it.
        out = Image.new("RGB", shot.size, BORDER_COLOR[theme])
        out.paste(shot, (0, 0), inner)
        out.putalpha(outer)  # transparent outside the rounded corners

        out.save(DST / src.name, optimize=True)
        print(f"{src.name}: {out.size}")


if __name__ == "__main__":
    main()
