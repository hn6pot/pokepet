# Poképote dans la barre des menus — spécification

Date : 20/10/2026 · Statut : approuvée, construite · S'ajoute à la spec principale [`2026-10-15-pokepet-design.md`](2026-10-15-pokepet-design.md), qui reste valable.

## 1. Pourquoi

Aujourd'hui, Poképote n'a aucune présence en dehors du compagnon flottant : l'app tourne en mode « accessoire » (ni Dock, ni barre des menus), et le seul menu est le clic droit sur le Pokémon.
L'idée vient de [PokeTokenBar](https://github.com/chattymin/PokeTokenBar), qui montre son Pokémon dans la barre des menus et ouvre une petite fenêtre au clic.
On reprend cette idée à notre façon : **le Pokémon du jour en haut de l'écran, et un clic qui ouvre un récap de la journée et quelques réglages.**

Ce que l'utilisateur veut lire en premier : ce que Claude a produit dans la journée (les tokens générés), puis l'activité du mois.

## 2. Ce qu'on construit

```
 Barre des menus :   … 🔋  [Minidraco animé]  Lun. 20 oct. 15:42
                                │ clic
                                ▼
                    ┌───────────────────────────────┐
                    │ [Minidraco]  Minidraco        │
                    │              Bébé · 14 / 30   │
                    │              avant Draco ▓▓░░ │
                    │  ┌ Récap ┐┌ Réglages ┐        │
                    │  AUJOURD'HUI                  │
                    │  Tokens générés       401 k   │
                    │  Tokens relus (cache) 144 M   │
                    │  Réponses de Claude      14   │
                    │  OCTOBRE                      │
                    │  Messages envoyés       575   │
                    │  automatiques (à part)  145   │
                    │  ───────────────              │
                    │  Quitter Poképote             │
                    └───────────────────────────────┘
```

La maquette retenue est l'option « deux onglets » (validée le 20/10).

### 2.1 L'icône dans la barre des menus

- Elle montre **le Pokémon du jour**, celui que montre le compagnon (même lignée, même stade, change au même moment, y compris après « Un autre Pokémon » et après une évolution).
- Il est **animé** en `Idle`, de face, à la taille de la barre des menus (environ 18 points de haut), en pixels nets (pas de lissage).
- Rien d'autre : **pas de chiffre, pas de « ! »** (demande explicite : « juste le Pokémon du jour »). La bulle « ! » reste sur le compagnon flottant.
- Un clic ouvre la fenêtre ; un second clic, ou un clic ailleurs, la ferme.

### 2.2 La fenêtre : l'en-tête (commun aux deux onglets)

- Le Pokémon du jour en grand (même animation `Idle`), son nom, son stade en mot (« Bébé », « Stade 2 », « Stade final »).
- La progression vers l'évolution suivante : « 14 / 30 réponses avant Draco », avec une barre. Au stade final : « Stade final », barre pleine.
- Les réponses comptées ici sont celles du Pokémon (comme aujourd'hui : remises à zéro par « Un autre Pokémon »).

### 2.3 L'onglet « Récap » (ouvert par défaut)

| Ligne | Ce qu'elle compte | Période |
|---|---|---|
| Tokens générés | les tokens écrits par Claude (`output_tokens`) | aujourd'hui |
| Tokens relus (cache) | les tokens relus depuis le cache (`cache_read_input_tokens`) | aujourd'hui |
| Réponses de Claude | le compteur du jour écrit par le mod (`~/.pokepet/jour/`), sans le décalage de « Un autre Pokémon » | aujourd'hui |
| Messages envoyés | les messages tapés par l'utilisateur dans Desktop ou le terminal | mois en cours |
| automatiques (à part) | les messages des lancements `claude -p` (Hermès…) | mois en cours |

Puis, sous un trait : « Quitter Poképote ».

Règles de comptage (vérifiées sur les journaux réels le 20/10) :
- **Source** : les journaux que Claude Code écrit déjà, `~/.claude/projects/**/*.jsonl` (sous-agents compris). Rien n'est envoyé sur internet, rien n'est demandé au trousseau.
- **« Aujourd'hui »** suit la journée de Poképote, qui bascule à 4 h (comme le compteur de réponses et le bébé du jour). **« Le mois »** est le mois civil de la journée Poképote en cours.
- **Toi ou automatique** : chaque ligne du journal porte un champ `entrypoint`. `cli` et `claude-desktop` = toi ; tout le reste (`sdk-cli` = `claude -p`, valeur absente…) = automatique.
- **Tokens générés et relus** : ne comptent **que tes conversations** (`cli`, `claude-desktop`), sous-agents compris. Les lancements automatiques n'apparaissent que sur la ligne « automatiques ».
- **Un message envoyé** = une ligne `type: "user"` qui contient du texte tapé (pas un résultat d'outil), hors sous-agents (`isSidechain`) et hors lignes système (`isMeta`, texte qui commence par `<`, comme les commandes `/…` et leurs sorties ; la marque « [Request interrupted… » écrite quand on appuie sur Échap ; le résumé écrit après un `/compact`, `isCompactSummary`). Une même ligne (même `uuid`) recopiée dans un autre fichier ne compte qu'une fois.
- **Une réponse de Claude produit plusieurs lignes** dans le journal (une par bloc de contenu), avec le même `message.id` : chaque `message.id` ne compte qu'une fois. Les chiffres sont presque toujours identiques d'une ligne à l'autre, mais pas toujours (14 réponses sur 8 496 le 20/10 : une première ligne à 3 tokens, puis 511) : on garde **le plus grand** `output_tokens` vu pour un même identifiant, ce qui oblige le registre à retenir la valeur comptée pour chaque identifiant, pas seulement l'identifiant (choix de la relecture).
- **Format** : « 401 k », « 144 M », « 1 042 » (espace fine pour les milliers, comme en français).

### 2.4 L'onglet « Réglages »

L'utilisateur m'a laissé choisir (« go ») ; c'est donc **mon choix**, à corriger à la relecture :

| Réglage | Effet |
|---|---|
| Afficher le compagnon (interrupteur) | cache ou montre le Pokémon flottant ; retenu d'un lancement à l'autre. Caché, il ne fait plus rien (pas de bulle « ! »), seule l'icône reste. |
| Taille (curseur) + « Taille normale » | la même taille que le pincement actuel, entre les mêmes bornes |
| Un autre Pokémon | comme le clic droit |
| Position par défaut | comme le clic droit |
| Quitter Poképote | comme le clic droit |

Le menu du clic droit sur le compagnon **ne change pas**.

### 2.5 Fraîcheur des chiffres

- Les chiffres se mettent à jour **à chaque ouverture de la fenêtre**, puis toutes les minutes tant qu'elle est ouverte.
- La lecture des journaux est **incrémentale** : on retient, pour chaque fichier, jusqu'où on l'a lu, et les totaux par jour. Les journaux pèsent environ 700 Mo pour le mois d'octobre (360 Mo touchés dans la seule journée du 20) : tout relire à chaque clic est exclu.
- Les totaux par jour sont gardés dans `~/.pokepet/usage.json` (nouveau fichier, écrit seulement par l'app). Ils survivent à la purge des vieux journaux par Claude Code.
- La première lecture (tout le mois) se fait en tâche de fond ; en attendant, les lignes affichent « … ». L'interface ne se fige jamais.
- Un fichier qui rétrécit ou disparaît : on garde les totaux déjà comptés, on relit le fichier depuis le début s'il a rétréci (en évitant les doublons grâce aux identifiants).

## 3. Objectifs, non-objectifs, anti-objectifs

**Objectifs**
1. L'icône montre toujours le même Pokémon que le compagnon.
2. Le récap affiche des chiffres justes, conformes aux règles du 2.3. Recomptage du 20/10 avec ces règles : environ 400 k tokens générés et 144 M relus dans la journée (à l'heure du recomptage) ; en octobre, **environ 575 messages tapés** dans Desktop et le terminal, et **145 automatiques**, affichés à part et non inclus dans les 575. (Un premier comptage annonçait 1 040 : il comptait aussi les messages envoyés aux sous-agents, 281, et les lignes système, 177.)
3. Ouvrir la fenêtre est instantané, même la première fois (les chiffres arrivent ensuite).

**Non-objectifs (plus tard, ou jamais)**
- L'onglet « Stats » (historique, comparaisons avec hier ou la moyenne) : prévu, mais pas maintenant.
- Le coût en dollars, les limites de 5 h ou de la semaine, les autres outils (Codex, Cursor…).
- « Lancer au démarrage » : le LaunchAgent de `make install` s'en charge déjà.
- Changer le menu du clic droit ou le mod.

**Anti-objectifs (raté même si ça marche)**
- La barre des menus qui bouge ou s'élargit (chiffres, texte) : l'icône reste une icône.
- Le Mac qui ralentit ou chauffe parce que Poképote relit des centaines de Mo.
- Des chiffres gonflés par les doublons du journal.

## 4. Contraintes

- Même pile que le reste : Swift 6.4, SwiftPM (`--build-system native`), AppKit ; la logique dans `PokepetCore` (testée), l'affichage dans `Pokepote` (vérifié à la main).
- L'utilisateur ne lit pas le Swift : chaque fichier reste petit, avec une seule responsabilité, et lui est expliqué en français.
- Tous les tests dans `tests/`, en reprenant l'arborescence du code ; les tests de lecture des journaux utilisent de petits fichiers `.jsonl` d'exemple écrits pour l'occasion (jamais de vrais journaux).
- Le code est en anglais ; l'interface, les messages et la doc en français. Commits Conventional Commits en français, identité noreply de `hn6pot`.
- Rien ne change dans le mod ni dans le contrat de fichiers existant (`sessions/`, `jour/`).
- Le dépôt est public : aucun sprite ajouté au dépôt.

## 5. Ce que je propose pour la construction (mes choix, ajustables par qui construit)

**Dans `PokepetCore` (logique testée)** — une responsabilité par fichier, noms indicatifs :
- `TranscriptEntry` : lit **une ligne** du journal et dit ce qu'elle est (message tapé, réponse avec ses tokens, autre), avec sa date, son origine (toi / automatique) et son identifiant.
- `UsageLedger` : les totaux par jour et par origine (messages, tokens générés, tokens relus), plus ce qui a déjà été lu (position par fichier, identifiants déjà comptés pour la période gardée) ; lecture et écriture de `~/.pokepet/usage.json`.
- `TranscriptScanner` : parcourt `~/.claude/projects`, lit seulement les octets nouveaux de chaque fichier et met le registre à jour.
- `Recap` : à partir du registre, de l'heure et du compteur de réponses, les chiffres de l'onglet (aujourd'hui, mois), selon la journée de Poképote.
- `EvolutionProgress` : « 14 / 30 avant Draco » ou « Stade final », à partir de l'apparence.
- `NumberFormat` : « 401 k », « 144 M », « 1 042 ».

**Dans `Pokepote` (affichage)** :
- `MenuBarIcon` : l'élément de la barre des menus, son animation, le clic qui ouvre ou ferme la fenêtre.
- `RecapPopover` : la fenêtre attachée à l'icône.
- `RecapTab` et `SettingsTab` : le contenu des deux onglets (SwiftUI dans la fenêtre AppKit, plus court à écrire et à lire que de l'AppKit pur).
- `Loops` expose ce qu'il faut (apparence courante, afficher ou cacher le compagnon, taille) ; `Preferences` gagne la clé de visibilité du compagnon.

**Laissé à qui construit** : les noms exacts, la durée de garde des identifiants déjà vus, l'ordre de lecture des fichiers, le rythme précis de l'animation de l'icône, le détail visuel de la fenêtre tant qu'il reste fidèle à la maquette.

## 6. Tests et vérification

- `make test` couvre : la lecture d'une ligne (chaque cas : message tapé, résultat d'outil, commande `/…`, sous-agent, ligne en double, réponse sur plusieurs lignes, `entrypoint` absent), la bascule à 4 h, le changement de mois, la lecture incrémentale (fichier qui grandit, qui rétrécit, qui disparaît), le format des nombres, la progression d'évolution.
- Vérification à la main après `make install` : l'icône apparaît et change avec « Un autre Pokémon » ; les chiffres du récap correspondent à un recomptage indépendant fait au même moment ; masquer puis réafficher le compagnon ; quitter depuis la fenêtre.
- Les docs (README EN et FR, spec principale) mentionnent l'icône et la fenêtre.
