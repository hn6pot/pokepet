#!/usr/bin/env python3
"""Fetches the sprites of pokepet's Pokémon from PMDCollab/SpriteCollab, at a pinned commit,
into sprites/pmd/<number>/, and regenerates CREDITS.md. The Makefile runs it the first time the
sprites are needed (make test, make run, make install), and again whenever this list changes: they are not in the repository, since
Pokémon art belongs to Nintendo / Chunsoft. Once installed, the app never downloads anything."""

import pathlib
import re
import urllib.request

COMMIT = "e7868e9a7f6b931d1fb826756a490d4633879d03"  # master as of 2026-10-15
SOURCE = f"https://raw.githubusercontent.com/PMDCollab/SpriteCollab/{COMMIT}"
POKEMON = {"0004": "Salamèche", "0005": "Reptincel", "0006": "Dracaufeu",
           "0172": "Pichu", "0025": "Pikachu", "0026": "Raichu",
           "0001": "Bulbizarre", "0002": "Herbizarre", "0003": "Florizarre",
           "0007": "Carapuce", "0008": "Carabaffe", "0009": "Tortank",
           "0155": "Héricendre", "0156": "Feurisson", "0157": "Typhlosion",
           "0158": "Kaiminus", "0159": "Crocrodil", "0160": "Aligatueur",
           "0147": "Minidraco", "0148": "Draco", "0149": "Dracolosse",
           "0092": "Fantominus", "0093": "Spectrum", "0094": "Ectoplasma",
           "0246": "Embrylex", "0247": "Ymphect", "0248": "Tyranocif",
           "0371": "Draby", "0372": "Drackhaus", "0373": "Drattak",
           "0129": "Magicarpe", "0130": "Léviator", "0130/0000/0001": "Léviator rouge"}
# The animations every Pokémon must have, then the optional gestures (Dracaufeu has few).
ANIMATIONS = ["Idle", "Walk", "Hop", "Rotate", "Hurt", "Sleep"]
GESTURES = ["Nod", "Pose", "LookUp", "DeepBreath", "Sit", "Swing"]
ROOT = pathlib.Path(__file__).resolve().parent.parent


def download(path: str) -> bytes:
    with urllib.request.urlopen(f"{SOURCE}/{path}", timeout=30) as response:
        return response.read()


def sheet(animdata: str, name: str) -> str:
    """The PNG sheet name of an animation: its own, or the one it copies (CopyOf)."""
    block = re.search(rf"<Anim>\s*<Name>{name}</Name>(.*?)</Anim>", animdata, re.S)
    if block is None:
        raise SystemExit(f"animation {name} absente")
    copy = re.search(r"<CopyOf>(\w+)</CopyOf>", block.group(1))
    return copy.group(1) if copy else name


def author_names() -> dict[str, str]:
    lines = download("credit_names.txt").decode().splitlines()[1:]
    return {columns[1]: columns[0] for columns in (l.split("\t") for l in lines) if len(columns) >= 2}


def main() -> None:
    names = author_names()
    credits = ["# Crédits des sprites", "",
               f"Sprites de [PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab), commit `{COMMIT}`.",
               "Bases : Pokémon Mystery Dungeon (Chunsoft). Ajouts de la communauté sous licence",
               "[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (usage non commercial, crédit obligatoire).",
               "Ces sprites ne sont pas dans le dépôt : `scripts/fetch_sprites.py` les télécharge à la première installation.",
               ""]
    for number, name in POKEMON.items():
        directory = ROOT / "sprites" / "pmd" / number
        directory.mkdir(parents=True, exist_ok=True)
        animdata = download(f"sprite/{number}/AnimData.xml").decode()
        (directory / "AnimData.xml").write_text(animdata)
        wanted = ANIMATIONS + [g for g in GESTURES if f"<Name>{g}</Name>" in animdata]
        for sheet_png in sorted({sheet(animdata, a) for a in wanted}):
            (directory / f"{sheet_png}-Anim.png").write_bytes(download(f"sprite/{number}/{sheet_png}-Anim.png"))
        authors: dict[str, set[str]] = {}
        for line in download(f"sprite/{number}/credits.txt").decode().splitlines():
            columns = line.split("\t")
            if len(columns) >= 5 and set(columns[4].split(",")) & set(wanted):
                authors.setdefault(names.get(columns[1]) or columns[1], set()).add(columns[3])
        credits.append(f"- **{name}** (`{number}`) : " + ", ".join(
            f"{author} ({', '.join(sorted(licenses))})" for author, licenses in sorted(authors.items())))
        print(f"{number} {name} : ok")
    (ROOT / "CREDITS.md").write_text("\n".join(credits) + "\n")


if __name__ == "__main__":
    main()
