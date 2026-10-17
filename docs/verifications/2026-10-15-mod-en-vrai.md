# Le mod en vrai — vérifications du 15/10/2026

Mod installé depuis le worktree (`claude plugin install pokepet@pokepet --scope user`). Un enregistreur notait chaque changement de `~/.pokepet/` toutes les 0,2 s.
Chaque ligne : ce qu'on a fait, ce qu'on attendait, ce qu'on a vu.

| # | Situation | Attendu | Vu |
|---|---|---|---|
| 1 | Conversation terminal, « bonjour » | `travaille` puis `fini`, `pid` présent, pas de `lien` ; compteur à 1 | OK après correctif : `travaille` → `fini`, compteur 1, pas de lien, pid 64998 = le vrai processus. Au premier essai le pid valait 0 (voir correctif 1). |
| 2 | `claude -p "dis bonjour"` | aucun fichier | OK : le mod est chargé (journal de débogage) et n'écrit rien. |
| 3 | Desktop, une question (AskUserQuestion) | `attend` avec lien `local_…`, puis `travaille` | OK après correctifs : `attend` 30 s, puis `travaille`. Avant : le mod ne se chargeait pas dans Desktop (correctif 2). |
| 4 | Desktop, `touch` en mode « Ask permissions » | `attend`, puis `travaille` après « Autoriser » | Vu OK avec `tool.check`, puis **abandonné** le 16/10 : en mode auto, `tool.check` donnait des « ! » sans personne à qui demander, et `PermissionRequest` n'atteint pas les plugins installés par soi-même. Les permissions ne font plus attendre (correctif 5, décision de Bérenger). |
| 5 | Un sous-agent Explore | le compteur ne prend que les réponses principales | OK : compteur 2 pour deux messages ; la fin du sous-agent n'a rien écrit. Dans le terminal, un sous-agent en arrière-plan relance un tour principal, compté comme une réponse. |
| 6 | `open` du lien écrit | l'app Claude affiche la conversation | OK : `setFocusedSession` sur la conversation visée. |
| 7 | Fermer la conversation terminal | `fermee` | OK après correctif : `fermee`. Avant : rien (correctif 3, puis 4). |

## Correctifs faits pendant ces vérifications

1. **Le pid.** `CLAUDE_PID` n'existe pas dans l'environnement du processus Claude Code, seulement dans celui des commandes qu'il lance : le mod lit le parent d'un `sh` (`$.process.run`).
2. **Le chargement dans Desktop.** L'app Desktop embarque Claude Code 2.1.295, qui refuse un mod passant `$` à une fonction importée d'un autre fichier : tout ce qui touche `$` est dans `register.ts`, et `make test` valide et teste aussi avec cette version.
3. **La fermeture.** À `session.end`, `$.session.surfaces()` est déjà vide.
4. **L'interface.** Dans Desktop, `$.session.surfaces()` est vide dès que la conversation n'est pas à l'écran (`fini` manquait) : l'interface se lit sur `CLAUDE_CODE_ENTRYPOINT` (`cli`, `claude-desktop` ; `sdk-cli` pour `claude -p`). Ce correctif rend le 3 inutile ; il est retiré.
5. **Les permissions (16/10, relecture finale).** Le « ask » de `tool.check` part aussi au classifieur du mode auto (faux « ! » pendant un sous-agent) ; le crochet `PermissionRequest` est filtré pour les plugins installés par soi-même (« bypassed by cc-plugin-sec-default »). Les permissions ne font plus attendre ; les questions et les plans sont suivis appel par appel.
