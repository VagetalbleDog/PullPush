"""Regenerate the code-drawn app icon. Requires Pillow."""

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
base = Image.new("RGB", (SIZE, SIZE), "#284D3B")
barbell = Image.new("RGBA", (SIZE, SIZE))
draw = ImageDraw.Draw(barbell)
color = "#D7EB93"
draw.rounded_rectangle((255, 479, 769, 545), radius=20, fill=color)
for left, top, right, bottom in [
    (240, 332, 330, 692),
    (150, 397, 223, 627),
    (694, 332, 784, 692),
    (801, 397, 874, 627),
]:
    draw.rounded_rectangle((left, top, right, bottom), radius=22, fill=color)
base.paste(barbell.rotate(40, resample=Image.Resampling.BICUBIC), mask=barbell.rotate(40, resample=Image.Resampling.BICUBIC))


def save(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    base.resize((size, size), Image.Resampling.LANCZOS).save(path)


save(ROOT / "assets/app_icon.png", 1024)
save(ROOT / "web/favicon.png", 32)
for size in (192, 512):
    for prefix in ("Icon", "Icon-maskable"):
        save(ROOT / f"web/icons/{prefix}-{size}.png", size)
for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    save(ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)
ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for item in json.loads((ios / "Contents.json").read_text())["images"]:
    size = round(float(item["size"].split("x")[0]) * float(item["scale"].rstrip("x")))
    save(ios / item["filename"], size)
