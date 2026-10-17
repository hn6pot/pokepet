# pokepet

<p align="center"><img src="docs/images/pokepote.png" alt="Charizard and Pikachu, in pixel art" width="336"></p>

**English** · [Français](README.fr.md)

**Poképote** is a Pokémon desk pet that floats above your Mac's windows and shows what Claude Code is doing:
it goes quietly about its business while Claude works, hops with a "!" bubble when a conversation is waiting for you
(one click opens it), spins when the work is done, and falls asleep when nothing happens.

Every morning at 4 a.m., a new baby is drawn from ten lineages (Charmander, Pichu, Bulbasaur, Squirtle, Cyndaquil,
Totodile, Dratini, Gastly, Larvitar, Bagon). It evolves after 30, then 80 Claude answers in the day.

The app's menus and the Pokémon names are in French.

## How it works

Two pieces, which only talk through files in `~/.pokepet/`:

- a **Claude Code mod** (`mod/`, TypeScript) writes the state of each conversation (working, waiting, done, failed) and the day's answer count;
- the **macOS app** (`app/`, Swift/AppKit) reads them every second and draws the pet.

Only conversations with an interface (desktop app, terminal) count; `claude -p` runs are ignored.
Detailed design (in French): [`docs/specs/2026-10-15-pokepet-design.md`](docs/specs/2026-10-15-pokepet-design.md).

## Requirements

- macOS 14 or later;
- Apple's Command Line Tools (`xcode-select --install`); Xcode is not needed;
- [Claude Code](https://claude.com/claude-code) (terminal or desktop app);
- Python 3 (shipped with the Command Line Tools) and an internet connection for the first install.

## Install

```bash
git clone https://github.com/hn6pot/pokepet.git
cd pokepet
make install
```

`make install` downloads the sprites (see below), runs the tests, builds `~/Applications/Poképote.app`,
registers it to start with your session (restarted if it crashes) and installs the mod for every Claude Code conversation.
The mod is installed from this folder: keep the clone where it is.

```bash
make uninstall
```

Removes the app, the automatic start, the mod and `~/.pokepet/`.

## Use

- **Click** the Pokémon or its bubble: opens the waiting conversation (desktop app); otherwise it hops and brings the Claude app to the front.
- **Drag**: move it (the position is remembered). **Scroll**: resize it, from 30 to 300 %.
- **Right-click**: its name, stage, today's answers, "Un autre Pokémon" (another Pokémon for the day), "Taille normale" (normal size), "Quitter Poképote" (quit).

## Develop

- `make test`: the logic tests (Swift Testing) and the mod tests (`claude plugin test`).
- `make run`: runs the app from the repository, without installing it.

## Fan project and sprites

Pokémon and Pokémon character names are trademarks and creations of Nintendo, Creatures and Game Freak. This project is
not affiliated with or endorsed by them; it is free and non-commercial.

**The sprites are not in this repository**, apart from this README's illustration (`docs/images/pokepote.png`, made from
the Charizard and Pikachu sprites). `scripts/fetch_sprites.py` downloads them from
[PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab), at a pinned commit, the first time they are needed.
They remain under SpriteCollab's terms: base sprites from *Pokémon Mystery Dungeon* (Chunsoft), community additions under
[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Credits: [`CREDITS.md`](CREDITS.md).

## License

The code is under the [MIT](LICENSE) license. It does not cover the sprites or the Pokémon characters.
