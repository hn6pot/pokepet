# Les attaques — spécification

Date : 18/11/2026 · Statut : approuvée le 19/11 · S'ajoute à la spec principale [`2026-10-15-pokepet-design.md`](2026-10-15-pokepet-design.md), dont le tableau « Ce que voit et fait le compagnon » (§ 5.1) reste valable, à une ligne près.

## 1. Pourquoi

Bérenger ne voit jamais le compagnon charger ou attaquer. Normal : `Charge` et `Attack` ne sont ni téléchargées ni jouées. `Charge` a été essayée au tout début, à chaque tour de Claude, et faisait vibrer le compagnon en permanence ; elle a été retirée le 16/10. Depuis, pendant que Claude travaille, il ne fait que six petits gestes (`Nod`, `Pose`, `LookUp`, `DeepBreath`, `Sit`, `Swing`) et quelques pas, et Dracaufeu, qui ne connaît que `Swing`, ne fait presque rien.

**Ce qu'on veut** : qu'il attaque de temps en temps pendant que Claude travaille, avec l'attaque de sa lignée quand elle existe, sans trembler.

## 2. Ce qu'on construit

Les attaques rejoignent les gestes : même tirage au hasard, même rythme (une action toutes les 15 à 30 s quand Claude travaille, un tiers de pas, deux tiers de gestes), jouées une fois puis retour à `Idle`. Rien ne change au repos, en attente ni pendant le sommeil.

| Animation PMD | Qui l'a | Ce que c'est |
|---|---|---|
| `Attack`, `Charge`, `Shoot`, `Strike` | toutes les lignées | l'attaque de base, la concentration, le tir, le coup |
| `Shock` | Pichu, Pikachu, Raichu | la décharge |
| `Lick` | Fantominus, Spectrum, Ectoplasma | la léchouille |
| `Withdraw` | Carapuce, Carabaffe, Tortank, Dracolosse | rentrer dans sa carapace |
| `Rumble` | Léviator, Draby, Drackhaus, Drattak | le grondement |
| `FlapAround` | Ymphect | battre des ailes |
| `Twirl` | Ectoplasma, Héricendre, Feurisson, Typhlosion, Kaiminus, Crocrodil, Embrylex, Tyranocif | la pirouette |
| `Dance`, `Shake` | Bulbizarre, Herbizarre, Florizarre | la danse, la secousse |
| `SpAttack` | Dracaufeu, Reptincel, Magicarpe, Minidraco, Aligatueur | l'attaque spéciale |
| `Kick` | Salamèche | le coup de pied |
| `Bite` | Draby | la morsure |

(`Double` existe partout mais n'est qu'une image dédoublée : on la laisse. `Appeal`, `Sing`, `Emit`, `RearUp`, `Ricochet`, `QuickStrike`, `MultiStrike` aussi, pour garder la liste courte ; on en ajoute si on les regrette.)

Validé le 18/11 : au hasard pendant le travail, pas sur un événement (c'est ce qui vibrait en octobre).

### 2.1 Ce qui change

- **`scripts/fetch_sprites.py`** : les onze noms ci-dessus s'ajoutent à `GESTURES`, téléchargés seulement quand `AnimData.xml` les déclare, comme les gestes aujourd'hui ; `CREDITS.md` est régénéré.
- **`Movement`** (`app/PokepetCore/SpriteSource.swift`) : onze cas de plus, tous dans `gestures`. Le reste de l'app les trouve tout seul : `Loops` ne garde déjà que les gestes dont la feuille existe pour l'espèce, et la zone cliquable est calculée sur toutes les images chargées.
- **La spec principale** (§ 5.1) : la ligne « travaille » cite les attaques.
- **`make install`** depuis le dépôt principal, pour télécharger les nouvelles feuilles.

### 2.2 Approches écartées

- **Une liste d'attaques à part, avec son propre poids** (par exemple une attaque pour deux gestes) : plus de contrôle, un paramètre de plus dans `Rhythm.action`, pour un gain qu'on ne sait pas encore vouloir. Si les attaques prennent trop de place (elles seront environ la moitié des gestes), on ajoutera le poids à ce moment-là.
- **Une attaque sur un événement** (fin d'un tour, réflexion de Claude) : lisible, mais c'est exactement ce qui faisait vibrer le compagnon ; Bérenger a tranché pour le hasard.

## 3. Hors périmètre

Aucun geste nouveau au repos ou en attente ; aucun réglage pour couper les attaques (le réglage existant de la taille et de l'affichage suffit) ; aucune direction autre que de face.

## 4. Vérification

- Les tests de `Rhythm` passent tels quels (la liste des gestes est un paramètre) ; un test de `Movement` vérifie que les onze attaques sont dans `gestures`.
- À la main, après `make install` : Salamèche fait `Kick`, `Attack` ou `Charge` dans les deux premières minutes de travail d'une conversation, et ne tremble pas.
