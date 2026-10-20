# pokepet

<p align="center"><img src="docs/images/pokepote.png" alt="Dracaufeu et Pikachu, en pixel art" width="336"></p>

[English](README.md) · **Français**

**Poképote** est un compagnon Pokémon qui flotte au-dessus des fenêtres du Mac et montre ce que fait Claude Code :
il agit tranquillement quand Claude travaille, saute avec une bulle « ! » quand une conversation t'attend (un clic l'ouvre),
fait une pirouette quand c'est fini, s'endort quand plus rien ne se passe.

Chaque matin à 4 h, un nouveau bébé est tiré parmi onze lignées (Salamèche, Pichu, Bulbizarre, Carapuce, Héricendre,
Kaiminus, Minidraco, Fantominus, Embrylex, Draby, Magicarpe, qui finit en Léviator rouge, chromatique). Il évolue à 30 puis 80 réponses de Claude dans la journée.

## Comment ça marche

Deux pièces, qui ne se parlent que par des fichiers dans `~/.pokepet/` :

- un **mod Claude Code** (`mod/`, TypeScript) écrit l'état de chaque conversation (travaille, attend, fini, échec) et le compteur du jour ;
- l'**app macOS** (`app/`, Swift/AppKit) les relit chaque seconde et dessine le compagnon.

Seules les conversations avec une interface (app Desktop, terminal) comptent ; les `claude -p` sont ignorés.
Conception détaillée : [`docs/specs/2026-10-15-pokepet-design.md`](docs/specs/2026-10-15-pokepet-design.md).

## Prérequis

- macOS 14 ou plus récent ;
- les Command Line Tools d'Apple (`xcode-select --install`), Xcode n'est pas nécessaire ;
- [Claude Code](https://claude.com/claude-code) (terminal ou app Desktop) ;
- Python 3 (fourni avec les Command Line Tools) et une connexion internet pour la première installation.

## Installer

```bash
git clone https://github.com/hn6pot/pokepet.git
cd pokepet
make install
```

`make install` télécharge les sprites (voir plus bas), lance les tests, construit `~/Applications/Poképote.app`,
l'inscrit au démarrage de session (relancé s'il plante) et installe le mod pour toutes les conversations Claude Code.
Le mod est installé depuis ce dossier : gardez le clone à sa place.

```bash
make uninstall
```

Enlève l'app, le démarrage automatique, le mod et `~/.pokepet/`.

## Utiliser

- **Clic** sur le Pokémon ou sa bulle : ouvre la conversation qui attend (app Desktop) ; sinon il saute et met l'app Claude au premier plan.
- **Glisser** : le déplacer (la position est retenue). **Molette** : la taille, de 30 à 300 %.
- **Clic droit** : son nom, son stade, les réponses du jour, « Un autre Pokémon » (repart bébé, compteur à zéro), « Position par défaut » (retour en bas à droite), « Taille normale », « Quitter Poképote ».
- **Barre des menus** : le Pokémon du jour s'y trouve aussi. Un clic ouvre une petite fenêtre à deux onglets :
  « Récap » (tokens générés et relus du cache aujourd'hui, réponses du jour, messages envoyés ce mois-ci, lancements `claude -p` à part)
  et « Réglages » (afficher ou cacher le compagnon, sa taille, les actions du clic droit).
  Les chiffres sont lus sur le Mac, dans les journaux de Claude Code (`~/.claude/projects`), et gardés dans `~/.pokepet/usage.json` ; rien ne sort du Mac.
  Sur un Mac à encoche dont la barre des menus est pleine, l'icône peut se cacher derrière l'encoche : la glisser vers la droite avec ⌘, ou masquer d'autres icônes dans Réglages Système › Barre des menus.
  Si le compagnon est caché et l'icône introuvable, rouvrir Poképote (`open -a Poképote`) le fait revenir.

## Développer

- `make test` : les tests de la logique (Swift Testing) et du mod (`claude plugin test`).
- `make run` : lance l'app depuis le dépôt, sans l'installer.

## Projet de fan et sprites

Pokémon et les noms des Pokémon sont des marques et créations de Nintendo, Creatures et Game Freak. Ce projet n'est ni
affilié ni approuvé par eux ; il est gratuit et non commercial.

**Les sprites ne sont pas dans ce dépôt**, à part l'illustration de ce README (`docs/images/pokepote.png`, composée à partir
des sprites de Dracaufeu et Pikachu). `scripts/fetch_sprites.py` les télécharge depuis
[PMD SpriteCollab](https://github.com/PMDCollab/SpriteCollab), à un commit figé, la première fois qu'ils sont nécessaires.
Ils restent soumis aux conditions de SpriteCollab : bases issues de *Pokémon Mystery Dungeon* (Chunsoft), ajouts de la
communauté sous licence [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Crédits : [`CREDITS.md`](CREDITS.md).

## Licence

Le code est sous licence [MIT](LICENSE). Elle ne couvre pas les sprites ni les personnages Pokémon.
