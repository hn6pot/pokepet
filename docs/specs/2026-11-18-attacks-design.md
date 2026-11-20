# Les attaques — spécification

Date : 18/11/2026 · Statut : approuvée et construite le 19/11 · S'ajoute à la spec principale [`2026-10-15-pokepet-design.md`](2026-10-15-pokepet-design.md), dont le tableau « Ce que voit et fait le compagnon » (§ 5.1) reste valable, à une ligne près.

## 1. Pourquoi

Bérenger ne voit jamais le compagnon charger ou attaquer. Normal : `Charge` et `Attack` ne sont ni téléchargées ni jouées. `Charge` a été essayée au tout début, à chaque tour de Claude, et faisait vibrer le compagnon en permanence ; elle a été retirée le 16/10. Depuis, pendant que Claude travaille, il ne fait que six petits gestes (`Nod`, `Pose`, `LookUp`, `DeepBreath`, `Sit`, `Swing`) et quelques pas, et Dracaufeu, qui ne connaît que `Swing`, ne fait presque rien.

**Ce qu'on veut** : qu'il attaque de temps en temps pendant que Claude travaille, avec l'attaque de sa lignée quand elle existe, sans trembler.

## 2. Ce qu'on construit

Les attaques rejoignent les gestes : même tirage au hasard, même rythme (une action toutes les 15 à 30 s quand Claude travaille, un tiers de pas, deux tiers de gestes), jouées une fois puis retour à `Idle`. Rien ne change au repos, en attente ni pendant le sommeil.

| Animation PMD | Qui l'a | Ce que c'est |
|---|---|---|
| `Attack`, `Charge` | toutes les lignées | l'attaque de base, la concentration |
| `Shoot`, `Strike` | presque toutes (constaté le 19/11 : Pichu n'a pas `Shoot` ; Pichu, Pikachu, Raichu, Carabaffe, Tortank, Draco, Spectrum et Draby ont `QuickStrike` ou `MultiStrike` au lieu de `Strike`) | le tir, le coup |
| `Shock` | Pichu, Pikachu, Raichu | la décharge |
| `Lick` | Fantominus, Spectrum, Ectoplasma | la léchouille |
| `Withdraw` | Carapuce, Carabaffe, Tortank, Dracolosse (chez lui, une copie d'`Emit`) | rentrer dans sa carapace |
| `Rumble` | Léviator, Draby, Drackhaus, Drattak | le grondement |
| `Dance`, `Shake` | Bulbizarre, Herbizarre, Florizarre | la danse, la secousse |
| `SpAttack` | Dracaufeu, Reptincel, Magicarpe, Minidraco, Kaiminus | l'attaque spéciale |
| `Kick` | Salamèche | le coup de pied |
| `Bite` | Draby | la morsure |

**Écartées le 19/11, après relecture** : `Twirl` (Ectoplasma, les Héricendre, Aligatueur, Embrylex, Tyranocif) et `FlapAround` (Ymphect) sont, dans les données épinglées, des copies de `Rotate`, l'animation qui annonce « fini » : un faux signal. Un test l'interdit désormais pour tout geste (`Rotate`, `Hop`, `Hurt`). Les Héricendre n'ont donc pas d'attaque propre.

(`Double` existe partout mais n'est qu'une image dédoublée : on la laisse. `Appeal`, `Sing`, `Emit`, `RearUp`, `Ricochet`, `QuickStrike`, `MultiStrike` aussi, pour garder la liste courte ; on en ajoute si on les regrette.)

Validé le 18/11 : au hasard pendant le travail, pas sur un événement (c'est ce qui vibrait en octobre).

### 2.1 Ce qui change

- **`scripts/fetch_sprites.py`** : les onze noms ci-dessus s'ajoutent à `GESTURES`, téléchargés seulement quand `AnimData.xml` les déclare, comme les gestes aujourd'hui ; `CREDITS.md` est régénéré.
- **`Movement`** (`app/PokepetCore/SpriteSource.swift`) : onze cas de plus, tous dans `gestures`. Le reste de l'app les trouve tout seul : `Loops` ne garde déjà que les gestes dont la feuille existe pour l'espèce, et la zone cliquable est calculée sur toutes les images chargées.
- **La spec principale** (§ 5.1) : la ligne « travaille » cite les attaques.
- **La fenêtre** est dimensionnée sur toutes les images chargées (`Loops.resize`) : avec `Strike` en 80×96, Feurisson passe de 72×72 à 80×96 pixels et Typhlosion de 72 à 80 de large ; Feurisson se trouve donc un peu plus haut dans sa fenêtre qu'avant. Les autres espèces gardent leur taille.
- **`make install`** depuis le dépôt principal, pour télécharger les nouvelles feuilles.

### 2.2 Approches écartées

- **Une liste d'attaques à part, avec son propre poids** (par exemple une attaque pour deux gestes) : plus de contrôle, un paramètre de plus dans `Rhythm.action`, pour un gain qu'on ne sait pas encore vouloir. Si les attaques prennent trop de place (en moyenne les deux tiers des gestes, jusqu'à 85 % pour les seize espèces qui n'avaient que `Swing` : une attaque toutes les 40 s environ, chacune de 0,3 à 0,6 s), on ajoutera le poids à ce moment-là.
- **Une attaque sur un événement** (fin d'un tour, réflexion de Claude) : lisible, mais c'est exactement ce qui faisait vibrer le compagnon ; Bérenger a tranché pour le hasard.

## 3. Hors périmètre

Aucun geste nouveau au repos ou en attente ; aucun réglage pour couper les attaques (le réglage existant de la taille et de l'affichage suffit) ; aucune direction autre que de face.

## 4. Vérification

- Les tests de `Rhythm` passent tels quels (la liste des gestes est un paramètre) ; un test de `Movement` vérifie que les attaques sont dans `gestures` ; un test parcourt les `AnimData.xml` et refuse tout geste dont la feuille est `Rotate`, `Hop` ou `Hurt`.
- À la main, après `make install` : Salamèche fait `Kick`, `Attack` ou `Charge` dans les deux premières minutes de travail d'une conversation, et ne tremble pas.
- Essai du 19/11, app du worktree lancée à la place de l'app installée pendant deux minutes de travail, douze captures : Fantominus animé (onze images distinctes), a évolué en Spectrum pendant l'essai, aucun tremblement, position stable aux promenades près ; une capture montre des étincelles au-dessus de lui, vraisemblablement `Charge`. Une attaque n'a pas été identifiée avec certitude sur des images fixes : à confirmer à l'œil après `make install`.
