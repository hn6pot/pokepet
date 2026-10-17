# pokepet — spécification

Date : 15/10/2026 · Statut : approuvée, puis ajustée par la répétition à blanc du plan (même jour) · Source des décisions : [`docs/cadrage.md`](../cadrage.md)

## 1. Ce qu'on construit

Un compagnon Pokémon animé qui flotte au-dessus de toutes les fenêtres du Mac et reflète ce que fait Claude Code.
Deux pièces qui ne se parlent que par des fichiers dans `~/.pokepet/` :

```
 Conversations Claude Code (Desktop, terminal)          App macOS « Poképote » (Swift/AppKit)
 ┌──────────────────────────────┐                      ┌──────────────────────────────────┐
 │ mod pokepet (TypeScript)     │  écrit               │ lit toutes les secondes          │
 │  - début de tour  → travaille│ ───────────────────► │  ~/.pokepet/sessions/*.json      │
 │  - question/plan/permission  │ ~/.pokepet/sessions/ │  ~/.pokepet/jour/<date>/*.json   │
 │                   → attend   │ ~/.pokepet/jour/     │                                  │
 │  - fin de tour → fini/échec  │                      │ calcule : état le plus urgent,   │
 │  - +1 réponse du jour        │                      │ Pokémon du jour, stade           │
 └──────────────────────────────┘                      │ dessine : fenêtre flottante      │
                                                       │ clic → claude://code/continue    │
                                                       └──────────────────────────────────┘
```

Critères de réussite :
1. Dans une conversation Desktop ou terminal, le compagnon passe à « travaille » au début d'un tour, « attend » sur une question, un plan ou une permission, « fini » ou « échec » à la fin.
2. Un `claude -p` (Hermès) ne change rien, ni l'état ni le compteur.
3. Un clic quand une conversation Desktop attend ouvre cette conversation dans l'app Claude.
4. Chaque matin (bascule à 4 h) un bébé de l'une des dix lignées ; stade 2 à 30 réponses, stade 3 à 80 (8 et 20 au départ, relevés le 17/10 : ça allait trop vite).
5. `make install` le lance au démarrage de session et le relance s'il plante ; `make uninstall` enlève tout.
6. `make test` passe : logique de l'app testée sans fenêtre, mod testé avec `claude plugin test`.

## 2. Vérification du point risqué : l'identifiant de session

**Résultat : `$.session.id()` ne convient pas, mais l'identifiant attendu est disponible autrement.**

| Constat | Source |
|---|---|
| `$.session.id()` renvoie « le nom du fichier transcript », un UUID (ici `6021228c-…`). | types de l'API des mods (`claude-code.d.ts`, `session.id`) |
| Le lien `claude://code/continue?session=…` n'accepte que `last` ou `^local_[A-Za-z0-9-]{1,64}$`, puis cherche une conversation Desktop non archivée dont `sessionId` est égal. | code de l'app Desktop 2.37337.1 (`app.asar`, gestionnaire `claudeURLHandler`) |
| Testé : avec l'UUID, l'app refuse (`claudeURLHandler: code entry link invalid ?session` dans `~/Library/Logs/Claude/main.log`) ; avec `local_…`, aucune erreur et l'app affiche la conversation. | essai `open claude://…` le 15/10 |
| L'app Desktop passe l'identifiant `local_…` à Claude Code dans la variable d'environnement `CLAUDE_CODE_HOST_SESSION_ID`. Son fichier de conversation confirme le lien : `sessionId: local_6b56…`, `cliSessionId: 6021228c-…`. | `env` du processus ; `~/Library/Application Support/Claude/claude-code-sessions/…` |
| Un mod peut lire cette variable : `$.env.get("CLAUDE_CODE_HOST_SESSION_ID")`. | API des mods (`$.env`) |

Conséquence pour la conception : le mod garde `$.session.id()` pour **nommer ses fichiers** (unique, présent partout, terminal compris)
et écrit le lien avec `CLAUDE_CODE_HOST_SESSION_ID` quand elle existe et commence par `local_`. Sans elle (terminal), pas de lien : le compagnon saute au clic.
Limite connue : une conversation archivée dans Desktop n'est plus trouvée par le lien (l'app ne fait alors rien).

## 3. Contrat de fichiers (`~/.pokepet/`)

C'est la seule interface entre le mod et l'app ; les deux côtés le testent.

**`~/.pokepet/sessions/<id>.json`** — une conversation, `<id>` = `$.session.id()`, écrit par le mod à chaque changement d'état :

```json
{ "etat": "attend", "majLe": "2026-10-15T14:02:11Z", "pid": 68387,
  "lien": "claude://code/continue?session=local_00000000-0000-4000-8000-000000000000" }
```

- `etat` ∈ `travaille`, `attend`, `fini`, `echec`, `fermee` (sans accents pour éviter les pièges d'encodage).
- `majLe` : heure UTC ISO 8601. `pid` : processus Claude Code, lu par le mod comme le parent d'un `sh` qu'il lance (`CLAUDE_PID` n'existe que pour les commandes de Claude, vérifié en vrai). `lien` : absent hors Desktop.

**`~/.pokepet/jour/<AAAA-MM-JJ>/<id>.json`** — `{ "reponses": 12 }`, le compteur du jour de cette conversation.
Chaque conversation n'écrit que son propre fichier : pas de course entre conversations ; l'app additionne.

**Journée** : la date locale de « maintenant moins 4 h » (à 3 h 59 le 16, on est encore le 15). Calculée des deux côtés, avec les mêmes cas de test.

**Écart avec le cadrage, à valider** : l'API de fichiers des mods sait lire, écrire, lister, mais **pas supprimer**.
Le mod écrit donc `etat: "fermee"` à la fermeture, et c'est l'app qui supprime les fichiers `fermee`, ainsi que ceux dont le `pid` n'existe plus (conversation plantée ou tuée).
Le contrôle du `pid` remplace aussi le cas « une conversation plantée en `attend` resterait affichée pour toujours ».

**Règles de lecture côté app** :
- fichier illisible ou JSON invalide → ignoré (jamais d'erreur affichée) ;
- `pid` mort ou `etat = fermee` → supprimé ;
- `majLe` de plus de 2 h → ignoré, sauf `attend` ;
- ordre d'urgence : `attend` > `echec` > `travaille` > `fini` > repos (aucun fichier retenu).

## 4. Le mod Claude Code (`mod/`)

Portée user, installé une fois ; n'affiche rien. Chaque crochet commence par vérifier qu'il y a une interface, et appelle toujours `next(e)` :
une erreur du mod (disque plein, etc.) est avalée et ne gêne jamais la conversation.

| Événement de l'API | Ce que fait le mod |
|---|---|
| `turn.start` | `etat = travaille` |
| `tool.call` sur `AskUserQuestion` ou `ExitPlanMode` | `etat = attend` avant `next(e)` |
| `tool.call` d'une question ou d'un plan, quand il rend la main | `travaille`, si plus aucune question ni aucun plan n'attend (plusieurs outils peuvent tourner à la fois) |
| `turn.complete` | raison `answer` → `fini` et +1 au compteur du jour ; `error` ou `refusal` → `echec` ; `aborted` (interruption par toi) → `fini` sans compter |

Les événements d'un sous-agent portent un `agentId` : sa fin de tour ne compte pas ; ses questions font attendre, comme celles de la conversation.

**Les demandes de permission ne font pas attendre** (décision de Bérenger, 16/10, après essai) : Claude Code ne transmet pas le crochet
`PermissionRequest` aux plugins qu'on installe soi-même (journal : « bypassed by cc-plugin-sec-default »), et le verdict `ask` de `tool.check`
part aussi au classifieur du mode auto, sans personne à qui demander (faux « ! » vu en vrai pendant un sous-agent). Avec le mode auto et `Bash(*)`
autorisé, les dialogues de permission sont rares.

Le mod retient le dernier état écrit pour n'écrire que les changements.

**« A une interface »** : `CLAUDE_CODE_ENTRYPOINT` vaut `cli` (terminal) ou `claude-desktop` (Desktop) ; `claude -p` donne `sdk-cli` (vérifié en vrai pour les trois).
`$.session.surfaces()` a été écarté après essai : dans Desktop, il est vide dès que tu regardes une autre conversation, et à la fermeture d'un terminal.

**Fichiers du mod** (TypeScript, exécuté par Claude Code, sans Node) :

| Fichier | Responsabilité |
|---|---|
| `mod/.claude-plugin/plugin.json` | Carte d'identité du mod (nom `pokepet`, version, description). |
| `mod/hooks/hooks.json` | Dit à Claude Code quel module charger (`./register.ts`). |
| `mod/hooks/register.ts` | Branche les événements du tableau ci-dessus, et contient tout ce qui touche `$` : l'interface (`CLAUDE_CODE_ENTRYPOINT`), le pid, l'écriture des fichiers (voir ci-dessous). |
| `mod/hooks/etat.ts` | Fonctions pures : quel état pour quel événement, quel contenu JSON écrire, quel lien construire, le compteur suivant. |
| `mod/hooks/journee.ts` | La date de la journée (bascule à 4 h). |
| `mod/hooks/chemins.ts` | Les chemins des fichiers dans `~/.pokepet/`. |
| `.claude-plugin/marketplace.json` (racine du dépôt) | Fait du dépôt un « magasin » local d'un seul mod, pour l'installer avec `claude plugin install`. |

La version de Claude Code embarquée dans l'app Desktop (2.1.295, vérifié en vrai) refuse de charger un mod qui passe `$` à une fonction importée d'un autre fichier : tout ce qui touche `$` vit donc dans `register.ts`, au niveau du fichier ; les autres fichiers sont purs. `make test` valide et teste le mod avec cette version aussi.

## 5. L'app macOS « Poképote » (`app/`)

Swift 6.4, SwiftPM, Command Line Tools (pas besoin d'Xcode). Deux cibles :
**`PokepetCore`**, toute la logique, sans fenêtre, entièrement testée ; **`Pokepote`**, la partie AppKit (fenêtre, souris, menu), mince, vérifiée à la main.
Le nom affiché est « Poképote » ; les identifiants techniques restent sans accent (`Pokepote`, `com.hn6pot.pokepote`).
Le projet, le mod et le dossier `~/.pokepet/` gardent le nom pokepet.

Avec les seuls Command Line Tools, le build système par défaut de SwiftPM 6.4 échoue (« Unknown error parsing property list ») :
le `Makefile` passe `--build-system native` et le chemin du framework Swift Testing (vérifié le 15/10).

### 5.1 Ce que voit et fait le compagnon

Il ne tremble jamais : quel que soit l'état, il est calme sur place (`Idle`), et le `Rythme` lui fait faire une action de temps en temps
(ajusté le 16/10 : l'animation `Charge`, jouée à chaque tour de Claude, faisait vibrer le compagnon presque en permanence).

| Situation | Animation PMD | Comportement |
|---|---|---|
| travaille | `Idle` | une action toutes les 15 à 30 s : quelques pas `Walk` (un tiers) ou un geste (`Nod`, `Pose`, `LookUp`, `DeepBreath`, `Sit`, `Swing` ; Dracaufeu n'a que `Swing`) |
| repos, fini, échec | `Idle` | une petite promenade toutes les 45 à 90 s, la fenêtre glisse sans sortir de l'écran |
| repos, fini ou échec, et aucun `majLe` plus récent que 15 min | `Sleep` | immobile, plus aucune action |
| attend | `Hop` ×3 puis `Idle` + bulle « ! » | trois sauts quand l'attente commence, puis un saut de rappel toutes les 20 s |
| fini | `Rotate` une fois | puis comme au repos |
| échec | `Hurt` une fois | puis comme au repos |
| changement de stade | flash blanc ≈ 0,5 s | puis le nouveau Pokémon |
| nouvelle journée (4 h) | flash blanc | le bébé du jour |
| animation absente (Dracaufeu) | `Idle` | — |

Au lancement, le compagnon apparaît directement au bon stade, sans flash.

**Gestes** : glisser = déplacer (position retenue) ; molette = taille de 30 à 300 % (100 % = pixels ×3, sans lissage) ;
clic = ouvre la conversation qui attend si elle a un lien ; sinon il saute et met l'app Claude au premier plan (en la lançant si elle est fermée), ou saute seulement si Claude est déjà devant ; clic droit = menu (nom, « Stade 2/3 », « Réponses aujourd'hui : 12 », « Un autre Pokémon », « Taille normale », « Quitter Poképote ») ;
toute la silhouette est cliquable (le rectangle des pixels visibles de l'image en cours, plus 2 pixels de marge), la bulle aussi ; les clics passent à travers le vide plus loin autour. Si la position retenue est hors de tout écran, il revient en bas à droite de l'écran principal.

**Les lignées** (dix depuis le 17/10, choisies par Bérenger ; au départ deux) : Salamèche → Reptincel → Dracaufeu ; Pichu → Pikachu → Raichu ;
Bulbizarre → Herbizarre → Florizarre ; Carapuce → Carabaffe → Tortank ; Héricendre → Feurisson → Typhlosion ; Kaiminus → Crocrodil → Aligatueur ;
Minidraco → Draco → Dracolosse ; Fantominus → Spectrum → Ectoplasma ; Embrylex → Ymphect → Tyranocif ; Draby → Drackhaus → Drattak.

**Tirage du jour** : la lignée est tirée de la date de la journée par une fonction de hachage stable (FNV-1a mélangée, modulo dix).
Même date, même bébé, même après un redémarrage, sans rien stocker. « Un autre Pokémon » (menu du clic droit) tire au hasard une des neuf autres lignées ; ce choix est retenu dans les réglages pour la journée seulement (jusqu'à 4 h), avec un flash au changement. (Le `hashValue` de Swift change à chaque lancement : on ne l'utilise pas.)

**Stade** : 0–29 réponses → bébé, 30–79 → stade 2, 80 et plus → stade 3.

### 5.2 Fichiers de `PokepetCore` (logique testée)

| Fichier | Responsabilité |
|---|---|
| `Lignee.swift` | Les dix lignées : noms français, numéros SpriteCollab. |
| `Journee.swift` | La date de la journée à partir de l'heure (bascule à 4 h). |
| `TirageDuJour.swift` | Quelle lignée pour une journée donnée (hachage stable de la date), une autre au hasard, et le choix du jour (`ChoixDuJour`). |
| `Stade.swift` | Quel stade pour un nombre de réponses (seuils 30 et 80). |
| `EtatSession.swift` | Le contenu d'un fichier `sessions/<id>.json` tel que décodé (état, heure, pid, lien). |
| `TriSessions.swift` | Règles de lecture : quels fichiers garder, ignorer ou supprimer (2 h, `fermee`, pid mort). Reçoit « ce pid est-il vivant ? » en paramètre pour être testable. |
| `EtatLePlusUrgent.swift` | Parmi les sessions gardées, l'état à afficher et le lien à ouvrir. |
| `LectureDossier.swift` | Lit `~/.pokepet/` sur le disque (sessions et compteurs du jour) et supprime les fichiers condamnés ; testé sur un dossier temporaire. |
| `CompteurDuJour.swift` | Additionne les `reponses` des fichiers du jour. |
| `Compagnon.swift` | Le « cerveau » : à partir de l'heure, de l'état urgent, du compteur et de l'heure de dernière activité, décide Pokémon, stade, animation, flash, balade autorisée ou non. |
| `AnimData.swift` | Lit `AnimData.xml` de PMD : pour chaque animation, taille des cases et durée de chaque image (en 1/60 s) ; une animation `CopyOf` reprend la planche d'une autre. |
| `Lecteur.swift` | Le minutage : quelle image afficher après tant de temps, en boucle ou une seule fois, et « l'animation est-elle finie ? ». |
| `SourceSprites.swift` | Le contrat d'une source de sprites : « donne-moi les images et durées de l'animation X du Pokémon Y, direction Z ». C'est ce qui rend la source interchangeable. |
| `SpritesPMD.swift` | La source PMD : lit `AnimData.xml` et découpe les planches PNG en images (CoreGraphics, sans fenêtre). |
| `Balade.swift` | Décide un pas de promenade (direction, distance, durée), sans sortir des bornes ; le hasard est injecté pour les tests. |
| `Rythme.swift` | Quand faire la prochaine action et laquelle (quelques pas, un geste, un saut de rappel), selon l'état ; rien quand il dort. |
| `ZoneCliquable.swift` | Le rectangle des pixels visibles d'une image (la silhouette cliquable) et « ce point est-il dans la bulle ? ». |
| `Reglages.swift` | Position, taille et lignée choisie du jour retenues ; borne la taille entre 30 et 300 %. |

### 5.3 Fichiers de `Pokepote` (AppKit, vérifiés à la main)

| Fichier | Responsabilité |
|---|---|
| `main.swift` | Point d'entrée : démarre l'app en mode « accessoire » (pas d'icône dans le Dock ni de menu en haut). |
| `AppDelegate.swift` | Assemble les pièces au démarrage : réglages, source de sprites, fenêtre, boucles. |
| `FenetreCompagnon.swift` | La fenêtre : sans bord, transparente, toujours au premier plan, présente sur tous les bureaux, ne vole pas le focus. |
| `VueSprite.swift` | Dessine l'image courante sans lissage, la bulle « ! » et le flash blanc. |
| `Boucles.swift` | Deux minuteries : 60 fois par seconde, avancer l'animation et la balade ; une fois par seconde, relire `~/.pokepet/` et demander au `Compagnon` quoi montrer. Met aussi à jour « clics traversants ou non » selon la position de la souris. |
| `Gestes.swift` | Traduit glisser, molette, clic, clic droit en actions. |
| `MenuContextuel.swift` | Construit le menu du clic droit. |
| `OuvrirConversation.swift` | Ouvre le lien `claude://…` via le système. |

### 5.4 Sprites (`sprites/`, `scripts/`)

- `scripts/fetch_sprites.py` (Python, livré avec macOS) : télécharge, pour les trente Pokémon, `AnimData.xml` et les planches des six animations communes, plus les gestes que chacun a, au commit `e7868e9` de SpriteCollab (figé dans le script), et régénère `CREDITS.md`. Les sprites (3,9 Mo) **ne sont pas dans le dépôt** depuis qu'il est public (17/10) : le `Makefile` lance le script la première fois qu'ils sont nécessaires (`make test`, `make run`, `make install`).
- `sprites/pmd/<numéro>/` : les fichiers récupérés (ignorés par Git).
- `CREDITS.md` : auteurs, licence CC BY-NC 4.0 pour les ajouts de la communauté, bases Chunsoft.

Les directions PMD (8 lignes par planche : bas, bas-droite, droite, haut-droite, haut, haut-gauche, gauche, bas-gauche) : face pour tout, droite/gauche pour `Walk`. `Sleep` n'a qu'une ligne. Les trente Pokémon ont les six animations communes ; les gestes varient (vérifié sur SpriteCollab).

## 6. Installation et lancement

| Fichier | Responsabilité |
|---|---|
| `Package.swift` | Décrit les deux cibles et la cible de tests, avec les chemins `app/…` et `tests/app/…`. |
| `Makefile` | `make test`, `make run` (lancer sans installer), `make app` (assembler `Poképote.app`), `make install`, `make uninstall`. |
| `packaging/Info.plist` | Fiche de l'app (`LSUIElement` : pas d'icône dans le Dock). |
| `packaging/com.hn6pot.pokepote.plist` | Le LaunchAgent : démarre à l'ouverture de session ; relance seulement en cas de plantage (`KeepAlive` / `SuccessfulExit = false`), donc « Quitter » reste quitté jusqu'à la prochaine session. |

`make install` : lance les tests, compile en mode release, assemble `~/Applications/Poképote.app` (binaire + `Info.plist` + sprites, signature locale), installe et charge le LaunchAgent,
puis installe le mod (`claude plugin marketplace add <dépôt>` puis `claude plugin install pokepet@pokepet --scope user`).
`make uninstall` fait l'inverse et supprime `~/.pokepet/`.

En cas de problème (sprites introuvables, etc.), l'app écrit dans `~/.pokepet/pokepet.log` et quitte avec une erreur ; launchd espace les relances.

## 7. Tests

Arborescence miroir dans `tests/` :

```
tests/app/PokepetCore/<Fichier>Tests.swift   (Swift Testing, `swift test`)
tests/mod/hooks/<fichier>.test.ts            (`claude plugin test`)
```

| Testé | Cas principaux |
|---|---|
| Journée (app et mod) | 03:59 le 16 → le 15 ; 04:00 → le 16 ; changement d'heure d'été |
| Tirage | même date → même lignée ; sur 2026, chaque lignée sort entre 15 et 65 jours ; le bébé change souvent d'un jour à l'autre |
| Stade | 0, 29, 30, 79, 80, 200 |
| Tri des sessions | 2 h pile, `attend` ancien gardé, `fermee` et pid mort supprimés, JSON cassé ignoré |
| État le plus urgent | toutes les combinaisons de l'ordre ; le lien vient de la session `attend` |
| Compteur du jour | somme, dossier absent → 0 |
| AnimData | lecture d'un vrai `AnimData.xml` du dépôt ; animation manquante |
| Lecteur | boucle, une fois, fin d'animation |
| Compagnon | sommeil après 15 min, flash au changement de stade, pas de flash au lancement, pas de balade en `travaille`/`attend` |
| Balade, zone cliquable, réglages | bornes de l'écran, pixel transparent/opaque, taille 29 % → 30 % |
| Mod | chaque événement écrit le bon état ; `claude -p` (aucune interface) n'écrit rien ; `answer` compte, `aborted` non ; lien seulement avec `local_…` ; une erreur d'écriture n'empêche pas `next(e)` |

`claude plugin test` cherche les tests dans le dossier du mod et refuse les imports qui en sortent : `make test` assemble un dossier temporaire (le mod, avec `tests/mod/` dedans) et le lance dessus ; les tests importent donc `../../../hooks/…`.
Non testé automatiquement : la fenêtre, la souris, le menu, l'ouverture du lien (vérification manuelle listée dans le plan).

## 8. Hors périmètre

Sprites lisses (Showdown) : seul le contrat `SourceSprites` est prévu, pas l'implémentation. Pas de son, pas de notifications, pas de réglages au-delà de la taille et de la position,
pas de prise en charge des conversations hors Mac (téléphone, cloud). Création du dépôt GitHub `hn6pot/pokepet` : dans le plan, pas dans le code.
