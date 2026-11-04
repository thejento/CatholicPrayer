"""Builds the bundled Roboto font files (DESIGN §9, ADR-043).

  pip install --require-hashes --no-deps -r tool/fonts/requirements.txt
  python tool/fonts/build_fonts.py       # writes assets/fonts/Roboto-*.ttf and OFL.txt

The web engine downloads Roboto from fonts.gstatic.com unless the app bundles
a family named "Roboto", so the app bundles one: the weights it uses, cut to
the characters of the three languages. The source is Google's variable Roboto
from github.com/google/fonts at a fixed commit, checked by SHA-256 (ADR-041).
"""
import hashlib
import sys
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / "build/fonts"
OUT = ROOT / "assets/fonts"
BASE = "https://raw.githubusercontent.com/google/fonts/1c627bfa375fc51cf86fabeca4f6e08a95f0aa5c/ofl/roboto/"
SOURCES = {
    "Roboto[wdth,wght].ttf": "d7598e12c5dbef095ff8272cfc55da0250bd07fbdecbac8a530b9b277872a134",
    "Roboto-Italic[wdth,wght].ttf": "9725a847af6b460ffca162ae66d20dad48b01876137947180b42d7dcd7887182",
    "OFL.txt": "061402327a96aadb0bfb694a960ed289ecd38d383e396243831ab81feb109c41",
}

# Output file → (source, weight). The weights the themes and screens use.
FACES = {
    "Roboto-Regular.ttf": ("Roboto[wdth,wght].ttf", 400),
    "Roboto-Medium.ttf": ("Roboto[wdth,wght].ttf", 500),
    "Roboto-SemiBold.ttf": ("Roboto[wdth,wght].ttf", 600),
    "Roboto-Bold.ttf": ("Roboto[wdth,wght].ttf", 700),
    "Roboto-ExtraBold.ttf": ("Roboto[wdth,wght].ttf", 800),
    "Roboto-Italic.ttf": ("Roboto-Italic[wdth,wght].ttf", 400),
}

# Latin, Latin-1, Latin Extended-A and B, spacing modifiers, general
# punctuation (dashes, quotes, the narrow no-break space of French), euro,
# trade mark, arrows, minus. test/data/font_coverage_test.dart checks that
# every character of the texts is in the font.
UNICODES = [
    *range(0x20, 0x7F), *range(0xA0, 0x250), *range(0x2B0, 0x300), *range(0x2000, 0x2070),
    0x20AC, 0x2122, *range(0x2190, 0x2194), 0x2212,
]


# Characters Roboto lacks, drawn with a glyph of the same width: the narrow
# no-break space that French puts before ; : ! ? (in the néo-Crampon) is a
# thin space that doesn't break.
ALIASES = {0x202F: 0x2009}


def add_aliases(font: TTFont):
    for table in font["cmap"].tables:
        if table.isUnicode():
            for alias, original in ALIASES.items():
                if original in table.cmap:
                    table.cmap[alias] = table.cmap[original]


def fetch(name: str) -> Path:
    path = CACHE / name
    if not path.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        path.write_bytes(urllib.request.urlopen(BASE + urllib.request.quote(name), timeout=60).read())  # noqa: S310
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != SOURCES[name]:
        sys.exit(f"{path} has SHA-256 {actual}, expected {SOURCES[name]}")
    return path


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for out, (source, weight) in FACES.items():
        font = instancer.instantiateVariableFont(TTFont(fetch(source)), {"wght": weight, "wdth": 100})
        add_aliases(font)
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        subsetter = subset.Subsetter(options)
        subsetter.populate(unicodes=UNICODES)
        subsetter.subset(font)
        font.save(OUT / out)
        print(f"{out}: {(OUT / out).stat().st_size // 1024} KB")
    (OUT / "OFL.txt").write_bytes(fetch("OFL.txt").read_bytes())


if __name__ == "__main__":
    main()
