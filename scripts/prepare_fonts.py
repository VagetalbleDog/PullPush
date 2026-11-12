"""Create portable static font faces from the upstream OFL variable fonts.

Usage: python scripts/prepare_fonts.py /path/to/Manrope.ttf /path/to/NotoSansSC.ttf
Requires fonttools. Static faces avoid renderer-dependent variable weight defaults.
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/fonts"
MANROPE, NOTO = map(Path, sys.argv[1:3])
ui_text = "".join(path.read_text() for path in (ROOT / "lib").rglob("*.dart"))


def make(source, family, name, weight, text=None):
    font = instantiateVariableFont(TTFont(source), {"wght": weight}, inplace=True)
    options = subset.Options()
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    subsetter = subset.Subsetter(options=options)
    if text:
        subsetter.populate(text=text)
    else:
        subsetter.populate(unicodes=font.getBestCmap().keys())
    subsetter.subset(font)
    destination = OUTPUT / f"{family}-{name}.ttf"
    font.save(destination)
    print(f"{destination.name}: {destination.stat().st_size:,} bytes")


for weight, name in [(400, "Regular"), (500, "Medium"), (600, "SemiBold"), (800, "ExtraBold")]:
    make(MANROPE, "Manrope", name, weight)
make(NOTO, "NotoSansSC", "Regular", 400)
make(NOTO, "NotoSansSC", "SemiBold", 600, ui_text + "".join(map(chr, range(32, 255))))
