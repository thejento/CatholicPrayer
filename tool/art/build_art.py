"""Builds the artwork shown on each mystery announcement (DESIGN §3.13, ADR-028).

  python tool/art/build_art.py      # needs Pillow; writes assets/art/*.webp and assets/data/art.json

Every image comes from a museum that releases it as CC0 or public domain; the
owner chose one painting per mystery from a shortlist. Images are resized to
at most 1200 px and encoded as WebP.

Each download is checked against its SHA-256 before it is decoded (ADR-041). A
museum that changes an image stops the build: look at the new image, then update
SHA256.
"""
import hashlib
import io
import sys
import json
import urllib.request
from collections import namedtuple
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/art"
UA = {"User-Agent": "RosaryCompanion-build/1.0 (https://github.com/thejento/CatholicPrayer)"}
MAX_SIDE = 1200

Art = namedtuple("Art", "url title artist date museum license page")

ART = {
    'joyful_1': Art(
        'https://api.nga.gov/iiif/e6497b39-66a9-4b6b-bf2b-c1633d20c0b6/full/!1600,1600/0/default.jpg',
        'The Annunciation', 'Masolino da Panicale', 'c. 1423/1424',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.18.html'),
    'joyful_2': Art(
        'https://api.nga.gov/iiif/53a3d42d-c211-4df6-b199-88086fdbd5a9/full/!1600,1600/0/default.jpg',
        'The Visitation with Saint Nicholas and Saint Anthony Abbot', 'Piero di Cosimo', 'c. 1489/1490',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.505.html'),
    'joyful_3': Art(
        'https://api.nga.gov/iiif/e66c8f60-ee91-46eb-9f70-a87ea34b76d4/full/!1600,1600/0/default.jpg',
        'The Nativity with the Prophets Isaiah and Ezekiel', 'Duccio di Buoninsegna', '1308-1311',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.10.html'),
    'joyful_4': Art(
        'https://api.nga.gov/iiif/a1871fb3-fa75-4868-ab25-8870b9e833c7/full/!1600,1600/0/default.jpg',
        'The Presentation in the Temple', 'Master of the Prado "Adoration of the Magi"', 'c. 1470/1480',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.46127.html'),
    'joyful_5': Art(
        'https://api.nga.gov/iiif/a3148763-333a-4e64-ae77-bd37a93b4a34/full/!1600,1600/0/default.jpg',
        'Christ among the Doctors', 'Master of the Catholic Kings', 'c. 1495/1497',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.41656.html'),
    'luminous_1': Art(
        'https://openaccess-cdn.clevelandart.org/1950.400/1950.400_print.jpg',
        'Baptism of Christ', 'Jacopo Tintoretto', '1580s',
        'The Cleveland Museum of Art', 'CC0', 'https://clevelandart.org/art/1950.400'),
    'luminous_2': Art(
        'https://api.nga.gov/iiif/25c98bc8-af28-4194-a056-daeae1f0a001/full/!1600,1600/0/default.jpg',
        'The Marriage at Cana', 'Master of the Catholic Kings', 'c. 1495/1497',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.41655.html'),
    'luminous_3': Art(
        'https://api.nga.gov/iiif/8c36f19a-c3c2-450f-b6b7-5217d1eafc82/full/!1600,1600/0/default.jpg',
        'The Calling of the Apostles Peter and Andrew', 'Duccio di Buoninsegna', '1308-1311',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.282.html'),
    'luminous_4': Art(
        'https://api.nga.gov/iiif/da5cec19-09ec-4c15-afef-68ea8e05ad25/full/!1600,1600/0/default.jpg',
        'The Transfiguration', 'Camillo Procaccini', 'c. 1590',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.53285.html'),
    'luminous_5': Art(
        'https://api.nga.gov/iiif/0db8b561-cb20-4940-bc13-3cf247f9c078/full/!1600,1600/0/default.jpg',
        'The Last Supper', 'Sebastiano Ricci', '1713/1714',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.12130.html'),
    'sorrowful_1': Art(
        'https://api.nga.gov/iiif/d525e201-d47c-40ed-9309-1d44ed1ff1ab/full/!1600,1600/0/default.jpg',
        'Scenes from the Passion of Christ: The Agony in the Garden', 'Andrea Vanni', '1380s',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.198423.html'),
    'sorrowful_2': Art(
        'https://api.nga.gov/iiif/618a3d88-ccc6-4fbd-8fbd-0e1d671ace07/full/!1600,1600/0/default.jpg',
        'The Flagellation of Christ', 'Bachiacca', 'c. 1512/1515',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.41696.html'),
    'sorrowful_3': Art(
        'https://api.smk.dk/api/v1/download/W3siaW1nX3VybCI6Imh0dHBzOi8vaWlwLnNtay5kay9paWlmL2pwMi9odDI0d244NW5fa21zc3AzNjUtY3JvcHBlZC50aWYuanAyL2Z1bGwvZnVsbC8wL25hdGl2ZS5qcGciLCJwdWJsaWNfZG9tYWluIjp0cnVlLCJvYmplY3RfbnVtYmVyIjoiS01Tc3AzNjUiLCJudW0iOiIifV0=/KMSsp365.jpg',
        'The Crowning with Thorns', 'Hendrick ter Brugghen', '1620',
        'Statens Museum for Kunst (SMK), Copenhagen', 'Public domain (PDM 1.0)', 'https://open.smk.dk/artwork/image/KMSsp365'),
    'sorrowful_4': Art(
        'https://api.nga.gov/iiif/64271c45-2acc-4011-a59f-0b79efc613db/full/!1600,1600/0/default.jpg',
        'Christ Carrying the Cross', 'Benvenuto di Giovanni', 'probably 1491',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.41667.html'),
    'sorrowful_5': Art(
        'https://openaccess-cdn.clevelandart.org/1931.449/1931.449_print.jpg',
        'The Crucifixion with a Carthusian Monk', 'Rogier van der Weyden', '1460',
        'The Cleveland Museum of Art', 'CC0', 'https://clevelandart.org/art/1931.449'),
    'glorious_1': Art(
        'https://openaccess-cdn.clevelandart.org/2017.192/2017.192_print.jpg',
        'The Resurrection of Christ', 'Johann König', '1622',
        'The Cleveland Museum of Art', 'CC0', 'https://clevelandart.org/art/2017.192'),
    'glorious_2': Art(
        'https://api.nga.gov/iiif/644d2492-3c7c-4f1e-ab33-c837edc019c2/full/!1600,1600/0/default.jpg',
        'The Ascension', 'Johann Koerbecke', '1456/1457',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.45890.html'),
    'glorious_3': Art(
        'https://api.smk.dk/api/v1/download/W3siaW1nX3VybCI6Imh0dHBzOi8vaWlwLnNtay5kay9paWlmL2pwMi9nZjA2ZzYxNnJfa2tzZ2I5NjY5XzM2LnRpZi5qcDIvZnVsbC9mdWxsLzAvbmF0aXZlLmpwZyIsInB1YmxpY19kb21haW4iOnRydWUsIm9iamVjdF9udW1iZXIiOiJLS1NnYjk2NjkvMzYiLCJudW0iOiIifV0=/KKSgb9669/36.jpg',
        'The Descent of the Holy Spirit', 'Albrecht Dürer', '1508-1511',
        'Statens Museum for Kunst (SMK), Copenhagen', 'Public domain (PDM 1.0)', 'https://open.smk.dk/artwork/image/KKSgb9669/36'),
    'glorious_4': Art(
        'https://api.nga.gov/iiif/7b1264b8-bb06-4d2a-992b-75bf1a3a5126/full/!1600,1600/0/default.jpg',
        'The Assumption of the Virgin', 'Michel Sittow', 'c. 1500',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.50280.html'),
    'glorious_5': Art(
        'https://api.nga.gov/iiif/6114c95d-1c1a-4785-88d1-c138e246adeb/full/!1600,1600/0/default.jpg',
        'The Coronation of the Virgin with Six Angels', 'Agnolo Gaddi', 'c. 1390',
        'National Gallery of Art, Washington', 'CC0', 'https://www.nga.gov/collection/art-object-page.344.html'),
}


SHA256 = {
    'joyful_1': '470f6827f46e1c5debaeccb9d63bf4ac81f9f0218ea9ffb5574bd2ceaeafbc7a',
    'joyful_2': 'df04c2a50da34f3db5ed2fb63743b4adbba92a888b97b951cf997741c16f4d3b',
    'joyful_3': '38dffb952cc80c1e12b0cde8950d88c2accc3ab55607fa3c2d139856c98648bc',
    'joyful_4': '5719a34d5bdbcc3c3a4f4a55695b6520c30ba84ed2f0f7e2ca67f58e39f14aa9',
    'joyful_5': 'e6fba8b500a2fae4f2646e102ea7c5c7ffc5a8a7d9f90a25d5bfa3074ef453a4',
    'luminous_1': '3ec7f722c11141337c98a884cd34c87cf09ed4f22e648603136bca0239ba046e',
    'luminous_2': 'f748dad5962d0210b227ab54c91e63e884e662e6c5ef64cdcafa74572393d5a4',
    'luminous_3': 'ba50708f2341bfc730a208f9845369e409ece7ac1f8b8cd3b485615df21b10d9',
    'luminous_4': 'de27083c28ab52c03459dd6c6ddba3374b6dc76a7c2e3906a65a9c3dd5219389',
    'luminous_5': '545be7205928b6afc90ecb6bd9423de40eb8c10d781e2d6a157ab2f6f7e26f26',
    'sorrowful_1': 'c9b3ae64c3892de0a645ca221954454d1f12fa044a42575072c3a6f5a229bb91',
    'sorrowful_2': '2da65650cc387aedd04b97845d000b62018bed5b3e5fce268bbea8ebc2d00152',
    'sorrowful_3': '42b03795f044029b7620e1c45ef74d44db10955e2c4bef14001904f948e7b338',
    'sorrowful_4': '2611fa1a7c06fa82c42619e9bb9b2854dfdd1c4e398ad8a1aaef1eba3ccd56c9',
    'sorrowful_5': '90c986e166f476ebcdee174e0560a7d795f708004095e2eb13393dfeb02ad78e',
    'glorious_1': 'f213c24c55e83432752c310ab3e6bf7c533c4627f22ceefc4481b7eee17af6e5',
    'glorious_2': 'bfe7e9ee0874cddba664c075c7585394295c24bcefe81cc685272e73b1aeecdb',
    'glorious_3': 'ca0de5b5bdfef76e6f4ff482a33817bdb7082baa5280c4756e6841ffc6a1caac',
    'glorious_4': '5915a6a7e7f97f4ab03ad08e0fc79628c96cdc041f198c3f1f176dbcd6e16598',
    'glorious_5': 'be59cc5a69d781dd8bda26bd1f46383f5cc8ac334f59c6328da687f7695b1c67',
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    credits = {}
    for key, art in ART.items():
        data = urllib.request.urlopen(urllib.request.Request(art.url, headers=UA), timeout=120).read()
        actual = hashlib.sha256(data).hexdigest()
        if actual != SHA256[key]:
            sys.exit(f"{key}: {art.url} has changed: SHA-256 {actual}, expected {SHA256[key]}")
        image = Image.open(io.BytesIO(data)).convert("RGB")
        image.thumbnail((MAX_SIDE, MAX_SIDE))
        image.save(OUT / f"{key}.webp", "WEBP", quality=80, method=6)
        credits[key] = {
            "file": f"assets/art/{key}.webp", "width": image.width, "height": image.height,
            **{f: getattr(art, f) for f in ("title", "artist", "date", "museum", "license", "page")},
        }
        print(f"{key}: {image.width}x{image.height} {(OUT / f'{key}.webp').stat().st_size // 1024} KB", flush=True)
    (ROOT / "assets/data/art.json").write_text(json.dumps(credits, ensure_ascii=False, indent=2) + "\n", "utf-8")


if __name__ == "__main__":
    main()
