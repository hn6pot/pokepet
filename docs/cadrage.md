# pokepet — cadrage validé (15/10/2026)

Décisions prises avec Bérenger dans une conversation de brainstorming (superpowers:brainstorming, parcours architectural).
Prochaine étape : écrire la spec à partir de ce cadrage, la faire relire, puis le plan (publié en page claude.ai), puis le code.

## L'idée

Un compagnon Pokémon animé qui vit sur l'écran du Mac, par-dessus toutes les fenêtres, et réagit à ce que fait Claude Code.
Un mod Claude Code ne peut dessiner que dans des zones fixes de l'interface (bandeau, panneau) : le compagnon est donc
une petite app macOS à part, alimentée par un mod. C'est le principe du « pet pop-out » de l'app Desktop d'Hermès
(`~/.hermes/hermes-agent/apps/desktop/electron/pet-overlay-ipc.ts`), à reproduire.

## Décisions

- **Un seul compagnon** pour toutes les conversations Claude ouvertes ; il montre l'état le plus urgent :
  attend > échec > travaille > fini > repos.
- **Un nouveau bébé chaque matin**, tiré au sort entre deux lignées ; le tirage est fixe pour la journée, qui bascule à **4 h**.
  - Feu : Salamèche → Reptincel → Dracaufeu
  - Électrik : Pichu → Pikachu → Raichu
- **Il évolue dans la journée** : stade 2 à **8** réponses de Claude terminées, stade 3 à **20** (mesure : 15 à 40 messages par jour ouvré).
  Seules comptent les conversations avec une interface (Desktop, terminal) ; les `claude -p` d'Hermès ne comptent pas.
- **Option A : app native Swift** (AppKit, SwiftPM), fenêtre sans bord, transparente, toujours au premier plan, sur tous les bureaux, sans icône dans le Dock.
- **Gestes** : glisser = déplacer (position retenue) ; molette = taille 30–300 % ; clic = ouvre la conversation qui attend
  (`claude://code/continue?session=<id>`, Desktop seulement ; sinon il saute) ; clic droit = menu (nom, stade, réponses du jour, taille normale, quitter) ;
  les clics passent à travers le vide autour du sprite.
- **Il se balade** au repos (quelques pas à gauche/droite, la fenêtre glisse) ; il reste sur place quand il attend.
- **Lancement** : LaunchAgent avec relance automatique ; `make install` / `make uninstall`.

## Le mod Claude Code

- N'affiche rien ; installé pour toutes les conversations (portée user) ; ne fait rien sans interface (`$.session.surfaces()`).
- Une conversation = un fichier `~/.pokepet/sessions/<id>.json` : état (`travaille` au début d'un tour, `attend` sur question/permission/plan,
  `fini` en fin de tour, `échec` si le tour finit en erreur), heure de mise à jour, lien `claude://` pour le Desktop ; supprimé à la fermeture.
- Compteur du jour par conversation : `~/.pokepet/jour/<date>/<id>.json` ; l'app additionne (pas de course entre conversations).
- L'app ignore les états de plus de 2 h, sauf `attend`.
- **Risque à vérifier en premier** : que `$.session.id()` soit bien l'identifiant attendu par `claude://code/continue`. Sinon, le clic ramène juste l'app Claude.

## Les sprites : PMD SpriteCollab (pour commencer)

- Source : https://github.com/PMDCollab/SpriteCollab (n° 0004, 0005, 0006, 0172, 0025, 0026), version figée par un script de récupération,
  sprites stockés dans le dépôt + `CREDITS.md` (crédits des auteurs, licence CC BY-NC 4.0 pour les ajouts de la communauté, bases Chunsoft). Dépôt privé, projet perso.
- Format : une planche PNG par animation, une ligne par direction (8), métadonnées dans `AnimData.xml` (taille des cases, durées en 1/60 s). Petites images (≈24×32 à 48×88) agrandies ×3/×4 sans lissage.
- Animations communes aux six (Dracaufeu en a moins) : repos `Idle` ; balade `Walk` (gauche/droite) ; travaille `Charge` ; attend `Hop` + bulle « ! » ;
  fini `Rotate` (une fois) ; échec `Hurt` ; rien depuis 15 min `Sleep` ; évolution = flash blanc puis nouveau Pokémon.
- **Garder la source de sprites interchangeable** : Bérenger veut ensuite essayer mieux, sans pixel-art. Piste notée : les GIF animés lisses de
  Pokémon Showdown (`https://play.pokemonshowdown.com/sprites/ani/<nom>.gif`, une seule animation, les mouvements seraient faits par l'app).
- Écartés : petdex (pixel-art, pas de Reptincel/Dracaufeu/Pichu/Raichu) ; génération via Hermès + OpenAI (le filtre d'OpenAI refuse les personnages protégés).

## Tests et organisation

- Une responsabilité par fichier ; tests dans `tests/` à la racine, même arborescence ; Bérenger ne connaît pas Swift : expliquer chaque fichier.
- Logique testée sans fenêtre : tirage du jour, stade selon compteur, état le plus urgent, fichiers périmés, lecture d'`AnimData.xml`, minutage. Mod testé avec l'outil de test des mods.

## Contexte utile

- Mods : doc officielle https://code.claude.com/docs/en/plugins/mods/overview ; skill `plugin-authoring` disponible dans Claude Code.
- L'app Claude Desktop du Mac embarque Claude Code 2.1.295 (mods OK depuis 2.1.287).
- Dépôt GitHub prévu : `hn6pot/pokepet` (privé), à créer avec le compte hn6pot (voir la fiche mémoire gh-compte-perso-hn6pot).
