# Les conversations terminal — spécification

Date : 04/11/2026 · Statut : approuvée le 04/11, construite le 05/11 · S'ajoute à la spec principale [`2026-10-15-pokepet-design.md`](2026-10-15-pokepet-design.md) et à celle de la barre des menus [`2026-10-20-menu-bar-design.md`](2026-10-20-menu-bar-design.md), qui restent valables.

## 1. Pourquoi

Le 3 novembre à 15:13, l'agent de fond « notion » (lancé par FleetView en `claude --bg` dans `~/WorkingLab`) a posé une question par `AskUserQuestion`. Le mod a écrit `attend`, le compagnon a montré sa bulle « ! », et elle est restée là 31 heures : le fichier d'état n'avait pas de `lien` (il n'y en a que dans l'app Desktop), donc le clic faisait sauter le Pokémon et ramenait l'app Claude devant, qui n'avait rien à montrer. Impossible de savoir d'où venait la question sans fouiller `~/.pokepet/sessions/`.

Le même cas existe pour un `claude` tapé à la main dans iTerm ou Terminal : bulle « ! », clic muet.

**Ce qu'on veut** : que la bulle dise qu'il s'agit d'une conversation terminal, et qu'un clic y amène, dans le terminal de son choix.

## 2. Ce qu'on construit

```
 Conversation Claude Code                 ~/.pokepet/sessions/<id>.json             Poképote
 ───────────────────────────              ──────────────────────────────            ────────────────────────────
 Desktop (CLAUDE_CODE_HOST_SESSION_ID) →  { etat, majLe, pid, lien }            →  bulle « ! »  · clic = ouvre Desktop
 claude --bg  (CLAUDE_JOB_DIR)         →  { etat, majLe, pid, job: "c5adc286" } →  bulle « >_ » · clic = terminal choisi + `claude attach c5adc286`
 claude dans iTerm (TERM_PROGRAM)      →  { etat, majLe, pid, terminal: "iTerm.app" } → bulle « >_ » · clic = iTerm au premier plan
 autre (claude -p, panneau inconnu)    →  { etat, majLe, pid }                  →  bulle « ! »  · clic = saute et montre Claude (comme aujourd'hui)
```

Validé le 04/11 : clic direct sans menu intermédiaire ; le choix du terminal dans l'onglet Réglages ; un `claude` à la main met son terminal au premier plan sans viser l'onglet ; bulle « >_ » comme signal ; et un réglage pour rendre tout cela optionnel.

### 2.1 Le mod écrit l'origine de la conversation

Deux champs facultatifs s'ajoutent au fichier `sessions/<id>.json`, écrits à chaque état comme `lien` l'est aujourd'hui :

- `job` : l'identifiant court de l'agent de fond, lu dans `CLAUDE_JOB_DIR` (son dernier segment, ici `c5adc286`). Écrit seulement s'il a la forme `^[0-9a-f]{8}$` : il finira dans une commande de terminal, aucune autre forme n'est acceptée.
- `terminal` : la valeur de `TERM_PROGRAM`, seulement si elle vaut `iTerm.app` ou `Apple_Terminal`. Toute autre valeur (ou son absence) n'écrit rien.

Les deux peuvent coexister dans l'environnement ; le mod écrit ce qu'il trouve, l'app tranche (§ 2.2). `lien` ne change pas. Rien ne change non plus pour `claude -p` : sans interface, le mod n'écrit toujours rien.

### 2.2 L'app : quelle conversation, quel geste

Parmi les sessions `attend` gardées, l'app prend **la plus récente** (`majLe`), comme aujourd'hui, et lit sa cible dans cet ordre : `lien`, puis `job`, puis `terminal`, sinon rien.

| Cible de la session qui attend | Bulle | Clic |
|---|---|---|
| `lien` | « ! » | ouvre la conversation Desktop (inchangé) |
| `job` | « >_ » | ouvre le terminal choisi et y lance `claude attach <job>` |
| `terminal` | « >_ » | met ce terminal (iTerm ou Terminal) au premier plan ; s'il ne tourne pas, saute seulement |
| aucune | « ! » | saute et met l'app Claude au premier plan, ou saute seulement si elle est déjà devant (inchangé) |

Aujourd'hui, `MostUrgentState` choisit le lien de la session `attend` la plus récente **qui a un lien**. Cette règle devient : la session `attend` la plus récente, point ; sa cible, quelle qu'elle soit. Une Desktop qui attend depuis 10 s passe donc avant un job qui attend depuis une heure, et inversement.

**La bulle « >_ »** : même cercle blanc cerclé de noir, même taille, le texte `>_` en police à chasse fixe grasse, bleu système, à la place du « ! » rouge. Le saut triple à l'entrée en attente, le rythme (un saut toutes les 20 s) et la zone cliquable ne changent pas.

**Lancer `claude attach`** : par AppleScript, le seul moyen qui marche pour iTerm (vérifié le 04/11 : iTerm n'exécute pas un fichier `.command` ouvert par `open -a iTerm`, Terminal si ; on prend le même mécanisme pour les deux).

```applescript
-- iTerm2
tell application "iTerm"
  activate
  create window with default profile command "/bin/zsh -lc '/Users/…/.local/bin/claude attach c5adc286; exec /bin/zsh'"
end tell

-- Terminal
tell application "Terminal"
  activate
  do script "/bin/zsh -lc '/Users/…/.local/bin/claude attach c5adc286; exec /bin/zsh'"
end tell
```

La commande passe par un shell qui reste ouvert après `attach` (`exec /bin/zsh`), pour les deux terminaux : le profil iTerm par défaut ferme la fenêtre dès que la commande se termine, et un `attach` qui échoue (job archivé, démon arrêté) disparaîtrait sans laisser lire son erreur (relevé par le relecteur, 04/11 ; mon choix). Le chemin du shell est fixe (`/bin/zsh`), jamais `$SHELL` : rien d'extérieur n'entre dans le script en dehors du chemin de `claude` et de l'identifiant, tous deux de forme vérifiée.

Le chemin de `claude` est cherché dans cet ordre : `~/.local/bin/claude`, `/opt/homebrew/bin/claude`, `/usr/local/bin/claude`. Sans binaire trouvé, ou si le script AppleScript lui-même échoue, le clic retombe sur « saute et montre Claude » et l'app journalise l'erreur (`AppDelegate.log`). Un échec d'`attach` lui-même se lit dans la fenêtre du terminal, pas dans le journal : pour l'app, le script a réussi.
L'app déclare `NSAppleEventsUsageDescription` dans `packaging/Info.plist` ; macOS demande une fois « Poképote veut contrôler iTerm / Terminal » (et le redemandera après chaque `make install`, la signature ad hoc changeant à chaque build : limite acceptée).

**Mettre un terminal au premier plan** : `NSRunningApplication` par identifiant de bundle, `com.googlecode.iterm2` ou `com.apple.Terminal`, puis `activate()`. Pas d'AppleScript ici, donc pas de permission.

### 2.3 Les réglages

Deux lignes de plus dans l'onglet Réglages, sous la taille :

```
 ┌ Réglages ──────────────────────────────┐
 │ Afficher le compagnon            [on]  │
 │ Taille                     ───●─────   │
 │ Suivre les conversations terminal [on] │
 │ Terminal              [ iTerm2  ▾ ]    │
 │ …                                      │
 └────────────────────────────────────────┘
```

- **« Suivre les conversations terminal »**, actif par défaut. Désactivé : une session `attend` dont la cible est `job`, `terminal` ou rien n'est plus montrée comme une attente, elle compte comme `travaille` (mon choix : pas de bulle muette, et le Pokémon ne dort pas tant que la conversation vit). Les Desktop ne changent pas. Le sélecteur de terminal est grisé.
- **« Terminal »** : iTerm2 ou Terminal. Par défaut iTerm2 s'il est installé (`NSWorkspace.urlForApplication(withBundleIdentifier:)`), sinon Terminal. Sert uniquement à `claude attach` : un `claude` à la main revient dans le terminal où il tourne, pas dans celui choisi.

Clés `UserDefaults` : `terminal.suivi` (Bool, absent = true) et `terminal.app` (`"iterm"` ou `"terminal"`, absent = le défaut ci-dessus).

## 3. Contrat de fichiers (`~/.pokepet/sessions/<id>.json`)

```json
{ "etat": "attend", "majLe": "2026-11-03T14:13:34Z", "pid": 87344, "job": "c5adc286" }
{ "etat": "attend", "majLe": "2026-11-04T09:00:00Z", "pid": 12345, "terminal": "iTerm.app" }
{ "etat": "attend", "majLe": "2026-11-04T09:00:00Z", "pid": 12345, "lien": "claude://code/continue?session=local_…" }
```

- `job` : `^[0-9a-f]{8}$`, absent sinon. `terminal` : `iTerm.app` ou `Apple_Terminal`, absent sinon. Les deux sont indépendants de `lien`.
- Un fichier avec un `job` ou un `terminal` d'une autre forme reste lisible : l'app ignore seulement le champ fautif (le mod n'est pas le seul à pouvoir écrire dans `~/.pokepet`, comme pour `lien`).
- Les anciens fichiers (sans ces champs) se lisent comme avant.

## 4. Ce qui a été vérifié le 04/11

| Constat | Source |
|---|---|
| L'agent « notion » a `CLAUDE_JOB_DIR=~/.claude/jobs/c5adc286`, `CLAUDE_BG_BACKEND=daemon`, `CLAUDE_BG_SOURCE=fleet`, pas de `TERM_PROGRAM`, et le mod y a bien écrit `attend` (entrée `cli`). | `ps -E` sur le pid 87344 ; `~/.pokepet/sessions/c5adc286-….json` |
| `claude attach <id|name>` rouvre un agent de fond dans le terminal courant ; **le nom est ambigu** (« notion » : 7 agents), l'identifiant court ne l'est pas. | `claude --help` ; `claude attach notion` |
| **`claude attach` lancé sans vrai terminal a répondu à la question en attente** (l'option 2 a été prise à 18:48, sans personne). Jamais d'`attach` hors d'un vrai terminal : l'app ne le lance que par le terminal, jamais par `Process`. | transcript de `c5adc286`, 17:48:45Z |
| `open -a Terminal x.command` exécute le script ; `open -a iTerm x.command` ne l'exécute pas. D'où AppleScript. | essai avec un script `echo` |
| Identifiants de bundle : `com.googlecode.iterm2`, `com.apple.Terminal`. | `mdls` sur `/Applications/iTerm.app` |
| Le lien Desktop prime déjà : une conversation Desktop a `CLAUDE_CODE_ENTRYPOINT=claude-desktop` et son `local_…` ; le mod n'y lit aucun `TERM_PROGRAM` utile. | `ps -E` sur cette session |

Non vérifié, à essayer à la main dans le plan : ce que fait `claude attach` quand le job est déjà attaché dans un autre terminal (deuxième vue, refus, ou vol de la session).

## 5. Non-buts et limites connues

- Pas de ciblage de l'onglet exact d'iTerm ou de Terminal (option refusée le 04/11) : le terminal passe devant, c'est tout.
- Un `claude` lancé dans le panneau Terminal de l'app Desktop, ou dans un terminal inconnu (Ghostty, Warp, VS Code…) : pas de `terminal` écrit, comportement d'aujourd'hui (« ! », saute et montre Claude). Ajouter un terminal = ajouter sa valeur `TERM_PROGRAM` et son bundle.
- Pas d'infobulle, pas de nom du job dans la bulle.
- Les agents de fond dont le processus est mort ne font pas de bulle (le triage supprime leur fichier) : inchangé.
- Les archives (`claude agents` ne liste plus le job) ne sont pas consultées : si `attach` échoue dans le terminal, l'erreur s'affiche là, dans la fenêtre restée ouverte.
- **Pas de détection « déjà attaché »** (mon choix, après la question du relecteur) : chaque clic sur « >_ » lance un nouvel `attach` dans une nouvelle fenêtre, même si un premier clic a déjà attaché le job ; le saut de rappel toutes les 20 s continue tant que la question n'a pas de réponse. Ce que fait alors `claude attach` (deuxième vue, refus, reprise de la session) se constate à la vérification manuelle et se note au § 4 ; on ne construit une détection (lire `claude agents --json` avant d'attacher, et passer le terminal devant si le job y est déjà) que si l'essai montre un vrai désagrément. Les premières versions restent simples.

## 6. Fichiers touchés

| Fichier | Changement |
|---|---|
| `mod/hooks/state.ts` | `jobId(env)` et `terminalName(env)` (fonctions pures, formes acceptées) ; `sessionContent` prend un objet `{ link, job, terminal }`. |
| `mod/hooks/register.ts` | `writeState` lit `CLAUDE_JOB_DIR` et `TERM_PROGRAM` et les passe. |
| `app/PokepetCore/SessionState.swift` | Champs `job: String?`, `terminal: String?` (clés `job`, `terminal`), formes vérifiées au décodage. |
| `app/PokepetCore/MostUrgentState.swift` | `Urgency.target: ClickTarget?` (`.desktop(link)`, `.job(id)`, `.terminal(TerminalApp)`) remplace `link` ; règle « la plus récente, point » ; prend le réglage « suivi » en paramètre. |
| `app/PokepetCore/ClickRule.swift` | Actions `.openConversation`, `.attachJob(id, in: TerminalApp)`, `.showTerminal(TerminalApp)`, `.hopAndShowClaude`, `.hop`. |
| `app/PokepetCore/Companion.swift` | `Appearance.bubble: Bubble` (`.none`, `.exclamation`, `.terminal`) et `target` à la place de `link`. |
| `app/PokepetCore/TerminalApp.swift` *(nouveau)* | `enum TerminalApp { iterm, terminal }` : valeur `TERM_PROGRAM`, identifiant de bundle, clé de préférence, nom affiché, et le script AppleScript d'`attach`. |
| `app/PokepetCore/Preferences.swift` | `terminalTracking: Bool`, `terminalApp: TerminalApp?` (nil = défaut selon l'installation, décidé par l'app). |
| `app/Pokepote/ConversationOpener.swift` | `attach(job:in:)` par `NSAppleScript`, `show(TerminalApp)`, chemin de `claude`. |
| `app/Pokepote/Loops.swift` | `click()` suit les nouvelles actions ; passe le réglage « suivi » au calcul. |
| `app/Pokepote/SpriteView.swift` | Dessine « ! » ou « >_ » selon `Bubble`. |
| `app/Pokepote/SettingsTab.swift`, `PopoverModel.swift` | Le toggle et le sélecteur. |
| `packaging/Info.plist` | `NSAppleEventsUsageDescription`. |
| `tests/mod/hooks/state.test.ts`, `register.test.ts` | Formes acceptées ; un job écrit `job`, un iTerm écrit `terminal`, une Desktop n'écrit ni l'un ni l'autre de travers. |
| `tests/app/PokepetCore/…` | `SessionStateTests`, `MostUrgentStateTests`, `ClickRuleTests`, `CompanionTests`, `PreferencesTests`, `TerminalAppTests`. |
| `docs/specs/2026-10-15-pokepet-design.md` | § 3 et le paragraphe « Gestes » renvoient ici. |
| `README.md` | Une phrase sur « >_ » et le réglage. |

## 7. Ce que les tests vérifient

- **Mod** : `job` écrit pour `c5adc286`, pas pour `../x` ni `C5ADC286` ; `terminal` écrit pour `iTerm.app` et `Apple_Terminal`, pas pour `vscode` ; le JSON est octet pour octet celui que Swift lit.
- **État le plus urgent** : la plus récente gagne quelle que soit sa cible ; cible dans l'ordre `lien` > `job` > `terminal` ; un `job` mal formé est ignoré ; suivi désactivé → une attente terminal compte `travaille`, une Desktop reste `attend`.
- **Clic** : chaque cible donne son action ; sans cible, la règle d'aujourd'hui.
- **Compagnon** : bulle « ! » pour Desktop, « >_ » pour job et terminal ; triple saut dans les deux cas.
- **Préférences** : valeurs absentes = défauts ; aller-retour des deux clés.
- **TerminalApp** : le script contient le chemin de `claude` et l'identifiant tels quels, le shell fixe `/bin/zsh -lc` et `exec /bin/zsh`, et rien d'autre venant de l'extérieur.
- À la main (`docs/verifications/`, avec le bundle de `make app`, le seul qui porte l'`Info.plist`) : clic « >_ » sur un job bloqué → iTerm s'ouvre, le job apparaît ; même chose avec Terminal choisi ; second clic alors que le job est déjà attaché (noter le comportement) ; `attach` d'un identifiant archivé → l'erreur reste lisible dans la fenêtre ; un `claude` dans iTerm qui pose une question → clic ramène iTerm ; suivi désactivé → plus de « >_ » ; permission AppleScript demandée une fois.

## 8. Laissé au constructeur

- Le détail du dessin de « >_ » (police, décalage) : seule contrainte, lisible à 100 % et à 30 %.
- Comment `Loops` passe le réglage « suivi » au calcul d'urgence (paramètre ou lecture des préférences au moment du tick).
- La forme exacte de la ligne du README.
