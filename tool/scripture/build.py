"""Builds the Bible passage of each mystery (DESIGN §3.9, ADR-024).

  python tool/scripture/build.py            # writes assets/data/scripture/{en,es,fr}.json
  python tool/scripture/build.py --raw es   # prints the Spanish source text before modernizing

Sources (downloaded into build/scripture/, never committed):
  en  Douay-Rheims 1899 American Edition, public domain       (eBible.org engDRA)
  fr  Sainte Bible néo-Crampon Libre, © 2022 Fraternité de Tibériade, CC BY-SA 4.0
                                                               (eBible.org francl)
  es  Torres Amat, 1836 edition, public domain                 (es.wikisource.org transcription)
      with the spelling modernized by tool/scripture/modern_es.py
"""
import html
import io
import json
import re
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / "build/scripture"
OUT = ROOT / "assets/data/scripture"

# Mystery → (book, chapter, first verse, last verse). Book codes follow eBible VPL.
PASSAGES = {
    "joyful_1": ("LUK", 1, 26, 38),
    "joyful_2": ("LUK", 1, 39, 56),
    "joyful_3": ("LUK", 2, 1, 20),
    "joyful_4": ("LUK", 2, 22, 38),
    "joyful_5": ("LUK", 2, 41, 52),
    "luminous_1": ("MAT", 3, 13, 17),
    "luminous_2": ("JOH", 2, 1, 12),
    "luminous_3": ("MAR", 1, 14, 15),
    "luminous_4": ("MAT", 17, 1, 8),
    "luminous_5": ("MAT", 26, 26, 28),
    "sorrowful_1": ("MAT", 26, 36, 46),
    "sorrowful_2": ("MAT", 27, 26, 26),
    "sorrowful_3": ("MAT", 27, 27, 31),
    "sorrowful_4": ("LUK", 23, 26, 32),
    "sorrowful_5": ("LUK", 23, 33, 46),
    "glorious_1": ("MAR", 16, 1, 7),
    "glorious_2": ("LUK", 24, 46, 53),
    "glorious_3": ("ACT", 2, 1, 13),
    # The Assumption is not narrated in Scripture; Tradition reads Revelation 12.
    "glorious_4": ("REV", 12, 1, 1),
    "glorious_5": ("REV", 12, 1, 1),
}

SOURCES = {
    "en": {
        "source": "Douay-Rheims Bible, 1899 American Edition",
        "license": "Public domain",
        "url": "https://ebible.org/Scriptures/engDRA_vpl.zip",
    },
    "fr": {
        "source": "Sainte Bible néo-Crampon Libre, © 2022 Fraternité de Tibériade",
        "license": "CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/), unmodified excerpts",
        "url": "https://ebible.org/Scriptures/francl_vpl.zip",
    },
    "es": {
        "source": "Sagrada Biblia, traducción de Félix Torres Amat (1836), ortografía modernizada",
        "license": "Dominio público",
    },
}

WIKISOURCE = {
    "MAT": "La_Sagrada_Biblia_(XIII)/Mateo",
    "MAR": "La_Sagrada_Biblia_(XIII)/Marcos",
    "LUK": "La_Sagrada_Biblia_(XIII)/Lucas",
    "JOH": "La_Sagrada_Biblia_(XIII)/Juan",
    "ACT": "La_Sagrada_Biblia_(XIV)/Hechos",
    "REV": "La_Sagrada_Biblia_(XV)/Apocalipsis",
}

def fetch(url: str, name: str) -> bytes:
    path = CACHE / name
    if not path.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(url, headers={"User-Agent": "RosaryCompanion-build/1.0"})
        path.write_bytes(urllib.request.urlopen(req, timeout=60).read())
    return path.read_bytes()


def vpl_verses(lang: str) -> dict:
    """{(book, chapter, verse): text} from an eBible VPL archive."""
    data = fetch(SOURCES[lang]["url"], f"{lang}.zip")
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        name = next(n for n in z.namelist() if n.endswith("_vpl.txt"))
        text = z.read(name).decode("utf-8-sig")
    verses = {}
    for line in text.splitlines():
        m = re.match(r"([1-3A-Z]{3}) (\d+):(\d+) (.*)", line)
        if m:
            verses[(m[1], int(m[2]), int(m[3]))] = m[4].strip()
    return verses


def wikisource_verses(book: str) -> dict:
    """{(book, chapter, verse): text} from the Torres Amat transcription."""
    api = ("https://es.wikisource.org/w/api.php?action=parse&prop=text&format=json&page="
           + urllib.parse.quote(WIKISOURCE[book]))
    page = json.loads(fetch(api, f"es-{book}.json"))["parse"]["text"]["*"]
    page = re.sub(r"<sup[^>]*class=\"reference\"[^>]*>.*?</sup>", "", page, flags=re.S)
    page = re.sub(r"<span[^>]*class=\"pagenum\"[^>]*>.*?</span>", "", page, flags=re.S)
    page = re.split(r"<(?:div|ol)[^>]*class=\"[^\"]*references", page)[0]
    # Each verse starts with <span title="chapter:verse" ...>verse</span>.
    marks = list(re.finditer(r'<span title="(\d+):(\d+)"[^>]*>\d+</span>', page))
    verses = {}
    for m, nxt in zip(marks, marks[1:] + [None]):
        chunk = page[m.end() : nxt.start() if nxt else len(page)]
        chunk = re.split(r"CAP[IÍ]TULO", chunk)[0]
        text = " ".join(html.unescape(re.sub(r"<[^>]+>", " ", chunk)).split())
        text = re.sub(r"\s+([,.;:!?»)])", r"\1", text).strip(" —")
        verses.setdefault((book, int(m[1]), int(m[2])), text)
    return verses


def passages(lang: str) -> dict:
    if lang == "es":
        from modern_es import modernize

        source = {}
        for book in {p[0] for p in PASSAGES.values()}:
            source.update(wikisource_verses(book))
        clean = lambda t: modernize(re.sub(r"\s*\[\d+\]", "", t))
    else:
        source = vpl_verses(lang)
        clean = lambda t: t
    out = {}
    for key, (book, chapter, first, last) in PASSAGES.items():
        verses = []
        for v in range(first, last + 1):
            text = source.get((book, chapter, v))
            if not text:
                sys.exit(f"{lang}: missing {book} {chapter}:{v} for {key}")
            verses.append({"v": v, "t": clean(text)})
        out[key] = {"chapter": chapter, "verses": verses}
    return out


def main():
    sys.path.insert(0, str(Path(__file__).parent))
    if len(sys.argv) == 3 and sys.argv[1] == "--raw":
        import modern_es

        modern_es.modernize = lambda t: t
        for key, p in passages(sys.argv[2]).items():
            for v in p["verses"]:
                print(f"{key} {p['chapter']}:{v['v']} {v['t']}")
        return
    OUT.mkdir(parents=True, exist_ok=True)
    for lang in ("en", "es", "fr"):
        meta = {k: v for k, v in SOURCES[lang].items() if k != "url"}
        doc = {"language": lang, **meta, "passages": passages(lang)}
        (OUT / f"{lang}.json").write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", "utf-8")
        print(f"{lang}: {sum(len(p['verses']) for p in doc['passages'].values())} verses")


if __name__ == "__main__":
    import urllib.parse  # noqa: F401  (used by wikisource_verses)

    main()
