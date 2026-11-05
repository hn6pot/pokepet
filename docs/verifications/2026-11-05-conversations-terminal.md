# Les conversations terminal en vrai — vérifications du 05/11/2026

Mod installé depuis le worktree (`claude plugin marketplace add <worktree>` puis `claude plugin install pokepet@pokepet --scope user`), app lancée depuis le bundle de `make app` (le seul qui porte l'`Info.plist` et sa clé `NSAppleEventsUsageDescription`), à la place de l'app installée (`launchctl bootout`).
Agent de fond d'essai : `claude --bg --name pokepet-essai "Pose-moi une seule question avec AskUserQuestion…"` lancé depuis le worktree (identifiant `a844d8ca`).
Chaque ligne : ce qu'on a fait, ce qu'on attendait, ce qu'on a vu.

| # | Situation | Attendu | Vu |
|---|---|---|---|
| 1 | Agent de fond qui pose une question | fichier avec `job`, bulle « >_ » | OK : `{"etat":"attend","majLe":"2026-11-05T09:59:43Z","pid":8774,"job":"a844d8ca"}` ; bulle « >_ » bleue au-dessus du Pokémon (capture). |
| 2 | Clic sur « >_ », réglage iTerm2 (défaut, iTerm installé) | macOS demande la permission une fois ; iTerm ouvre une fenêtre, le job apparaît avec sa question | OK (Bérenger, agent `6cee9594`) : « fonctionne parfaitement ». Pas de ligne dans `pokepet.log`. |
| 3 | Répondre dans cette fenêtre | la bulle disparaît ; la fenêtre reste ouverte sur un shell | OK : fichier passé à `fini` 26 s après la question (`"majLe":"2026-11-05T11:20:21Z"`), bulle disparue. |
| 4 | Même scénario, réglage Terminal | Terminal ouvre une fenêtre, le job apparaît | OK (Bérenger, agent `8f95dc4b`, réglage `terminal.app = terminal`) : « ça fonctionne parfaitement ». |
| 5 | Second clic sur « >_ » alors que le job est déjà attaché | noter ce qui se passe | Fait par Bérenger dans la même passe (« fonctionne parfaitement ») ; le détail (double vue ou reprise) n'a pas été noté. Pas de détection ajoutée (spec § 5). |
| 6 | Identifiant de job inconnu (fichier `job` forgé avec le pid de l'app) | la fenêtre reste ouverte avec l'erreur d'`attach` lisible | **Non vérifié** (clic). |
| 7 | `claude` lancé à la main dans iTerm, une question | fichier avec `terminal: "iTerm.app"`, bulle « >_ », clic = iTerm au premier plan | **Non vérifié en vrai.** Essai par `TERM_PROGRAM=iTerm.app claude --bg` : le démon ne transmet pas la variable au job (fichier avec `job` seul), donc inconclusif ; le chemin `terminal` n'est couvert que par les tests du mod et de l'app. |
| 8 | Conversation Desktop, une question | bulle « ! », clic ouvre Desktop : inchangé | Bulle « ! » vue pendant la passe (trois Desktop en attente à 11:19, plus récentes que le job : la bulle était « ! », d'où le relancement du job d'essai). Clic non rejoué. |
| 9 | Suivi désactivé, job en attente | plus de « >_ », le Pokémon travaille ; une Desktop en attente garde « ! » | OK (agent `46e1f347`, `defaults write … terminal.suivi -bool false`) : la bulle disparaît dans la seconde, revient quand le réglage est effacé. La moitié « Desktop garde « ! » » n'est tenue que par le test `withTrackingOffADesktopWaitStillWins`. |
| 10 | `claude` introuvable | le compagnon saute et montre Claude ; une ligne dans le journal | **Non vérifié** (clic). |

## Notes

- **Plantage vu pendant la passe (14:15)** : `SIGABRT` dans `SpriteView.drawBubble`, à la mesure du texte « >_ » (`NSAttributedString.size()` → CoreText `TAttributes::ApplyFont` → `NSDictionary` avec un objet nul), avec la police `monospacedSystemFont` de la version du matin. Pas reproduit hors de l'app, à aucune taille (0, NaN, infini, 10⁶ compris). Correctif : le glyphe est dessiné en traits (`NSBezierPath`), sans police ; au passage il est centré, ce que Bérenger avait relevé (« le >_ est pas centré bien »). Rapport : `~/Library/Logs/DiagnosticReports/Pokepote-2026-11-05-141540.ips`.

- Le clic ne peut pas être joué par script (`System Events` refusé à `osascript` : accessibilité) ; les lignes 2, 3 et 5 ont été jouées par Bérenger, les autres clics restent à faire à l'occasion.
- La règle « la plus récente gagne » se voit en vrai : trois conversations Desktop qui attendaient après le job ont pris la bulle (« ! ») ; il a fallu relancer un job pour revoir « >_ ».
- Agents d'essai (`pokepet-essai`, `-2`, `-3`, `-4`) arrêtés par `claude stop` ; leurs transcripts restent dans `~/.claude/projects/` du worktree.
