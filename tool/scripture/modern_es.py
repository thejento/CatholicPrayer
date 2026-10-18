"""Modernizes the 1836 spelling of the Torres Amat passages (ADR-024).

Only spelling changes: accents, j/g, y/i, ph/th, proper names in today's
Spanish form, and a few transcription errors in the Wikisource text. The
wording of the translation is not changed.
"""
import re

# Errors in the Wikisource transcription, checked against the 1836 scan.
TRANSCRIPTION = {
    "Se ñor": "Señor",
    "apre suradamente": "apresuradamente",
    "enla ": "en la ",
    "por tado": "portado",
    "Sepuiltaduos": "Sepultadnos",
    "( le bendijo)": "(le bendijo)",
    "digo á Jesus": "dijo á Jesus",
    "se turbo,": "se turbó,",
}

# Words whose stress or meaning needs a context to decide.
PHRASES = {
    "á el habeis": "a él habéis",
    "Pero el les dijo": "Pero él les dijo",
    "estamos en el justamente": "estamos en él justamente",
    "en mi segun": "en mí según",
    "á si mismo": "a sí mismo",
    "á mi tanto": "a mí tanto",
    "mas allá": "más allá",
    "creyeron mas": "creyeron más",
    "el mas flojo": "el más flojo",
    "lo mas alto": "lo más alto",
    "aun no es": "aún no es",
    "retiró aun": "retiró aún",
    "á fuera": "afuera",
    "en cinta": "encinta",
    "Espíritu santo": "Espíritu Santo",
}

WORDS = {
    # Proper names in their modern Spanish form.
    "Christo": "Cristo", "Moysés": "Moisés", "Israél": "Israel", "Jerusalem": "Jerusalén",
    "Bethlehem": "Belén", "Nazareth": "Nazaret", "Joseph": "José", "Elisabeth": "Isabel",
    "Zachârías": "Zacarías", "Cyrino": "Cirino", "Syria": "Siria", "Cyrene": "Cirene",
    "Gethsemaní": "Getsemaní", "Capharnaum": "Cafarnaúm", "Bethania": "Betania",
    "Barrabas": "Barrabás", "Phanuel": "Fanuel", "Anna": "Ana", "Simon": "Simón",
    "Simeon": "Simeón", "Jordan": "Jordán", "Pentecostes": "Pentecostés", "Parthos": "Partos",
    "Cappadocia": "Capadocia", "Phrygia": "Frigia", "Pamphylia": "Panfilia",
    "Egypto": "Egipto", "Lybia": "Libia", "Jesus": "Jesús", "Maria": "María", "Amen": "Amén",
    # Old spellings.
    "muger": "mujer", "Muger": "Mujer", "mugeres": "mujeres", "ropage": "ropaje",
    "hydrias": "hidrias", "jóven": "joven", "contínuo": "continuo", "Entónces": "Entonces",
    "entónces": "entonces", "tí": "ti", "dió": "dio", "Dió": "Dio", "vió": "vio",
    "Levantáos": "Levantaos", "Sentáos": "Sentaos", "buscábais": "buscabais", "llevára": "llevara",
    # Accents the 1836 spelling left out.
    "dia": "día", "dias": "días", "habia": "había", "Habia": "Había", "habian": "habían",
    "decia": "decía", "Decia": "Decía", "decian": "decían", "venia": "venía", "sabia": "sabía",
    "sabian": "sabían", "solian": "solían", "volvian": "volvían", "crecia": "crecía",
    "oia": "oía", "oian": "oían", "herian": "herían", "escarnecian": "escarnecían",
    "plañian": "plañían", "deshacian": "deshacían", "cabian": "cabían", "resistia": "resistía",
    "reprendia": "reprendía", "ponia": "ponía", "hacian": "hacían", "bendecia": "bendecía",
    "debia": "debía", "Vivia": "Vivía", "creido": "creído", "oir": "oír", "oimos": "oímos",
    "mio": "mío", "aqui": "aquí", "segun": "según", "despues": "después", "Despues": "Después",
    "tambien": "también", "perdon": "perdón", "corazon": "corazón", "varon": "varón",
    "meson": "mesón", "sazon": "sazón", "latin": "latín", "ningun": "ningún", "algun": "algún",
    "teneis": "tenéis", "habeis": "habéis", "venis": "venís", "lloreis": "lloréis",
    "tengais": "tengáis", "hayais": "hayáis", "seais": "seáis", "viendole": "viéndole",
    "poniendose": "poniéndose", "caido": "caído", "poseidos": "poseídos",
}


def modernize(text: str) -> str:
    for old, new in TRANSCRIPTION.items():
        text = text.replace(old, new)
    for old, new in PHRASES.items():
        text = text.replace(old, new)
    # The one-letter words á, ó, é, ú lost their accent in 1911.
    text = re.sub(r"\b([áóéú])\b", lambda m: "aoeu"["áóéú".index(m[1])], text)
    text = re.sub(r"\b(\w+?)cion(es)?\b", lambda m: m[1] + ("ciones" if m[2] else "ción"), text)
    text = re.sub(r"\b(\w+?)sion\b", r"\1sión", text)
    return re.sub(r"\b\w+\b", lambda m: WORDS.get(m[0], m[0]), text)
