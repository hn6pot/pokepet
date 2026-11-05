# Les conversations terminal — plan d'implémentation

> **Pour les agents :** sous-skill requis : superpowers:subagent-driven-development (recommandé) ou superpowers:executing-plans, tâche par tâche. Les étapes se cochent (`- [ ]`).

**But :** quand la conversation qui attend est un agent de fond (`claude --bg`) ou un `claude` tapé dans iTerm ou Terminal, la bulle montre « >_ » et le clic ouvre le terminal choisi avec `claude attach <id>`, ou met le terminal de la conversation au premier plan ; un réglage rend ce suivi optionnel.

**Architecture :** le mod ajoute deux champs facultatifs au fichier d'état (`job`, `terminal`), lus dans l'environnement. Dans `PokepetCore`, la cible d'un clic devient une valeur (`ClickTarget` : Desktop, job ou terminal) calculée par `MostUrgentState`, la bulle une valeur (`Bubble`), le clic une action de plus (`attachJob`, `showTerminal`) ; `TerminalApp` porte tout ce qui est propre à iTerm2 et à Terminal (bundle, nom, script). La cible `Pokepote` ne fait qu'exécuter : dessiner « >_ », lancer le script AppleScript, activer un terminal, et brancher deux réglages.

**Outils :** Swift 6 (SwiftPM, Swift Testing, AppKit, SwiftUI pour l'onglet Réglages), Command Line Tools, make ; TypeScript pour le mod, testé par `claude plugin test`.

**Spec :** [`docs/specs/2026-11-04-terminal-conversations-design.md`](../specs/2026-11-04-terminal-conversations-design.md) · spec principale : [`docs/specs/2026-10-15-pokepet-design.md`](../specs/2026-10-15-pokepet-design.md)

**Base :** `origin/main` au commit `0c04184`, branche `feat/terminal-conversations`, worktree `.worktrees/feat-terminal-conversations` (la spec y est déjà commitée, `d04003d`).

## Contraintes globales

- macOS 14 et plus ; Swift 6, mode strict ; aucun paquet tiers ; Command Line Tools seuls (pas de `@State` SwiftUI : l'état des vues vit dans `PopoverModel`, `@Observable`).
- Compiler et tester par le `Makefile` : `make test-app FILTER=<mot>` et `make test-mod` ; `make app` pour le bundle de vérification. Dans le worktree, les sprites ne sont pas là : `ln -s /Users/berengerouadi/WorkingLab/personal/pokepet/sprites sprites` (chemin absolu, pour que le bundle de `make app` les trouve aussi) avant le premier `make`.
- Une responsabilité par fichier ; tests dans `tests/app/PokepetCore/` et `tests/mod/hooks/`, en miroir ; noms de tests `@Test("…")` en français, fonctions en anglais ; tests du mod `test('…')` en français.
- Code en anglais ; interface, messages et docs en français ; commits Conventional Commits **en anglais**, identité du dépôt (`hn6pot <22932896+hn6pot@users.noreply.github.com>`), avec la ligne `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Le format du fichier `sessions/<id>.json` est partagé avec l'app installée : clés en français (`etat`, `majLe`, `pid`, `lien`) plus `job` et `terminal` ; ordre des clés `etat, majLe, pid, lien, job, terminal` ; heure sans millisecondes.
- `job` ∈ `^[0-9a-f]{8}$` ; `terminal` ∈ `iTerm.app`, `Apple_Terminal`. Tout autre contenu est ignoré des deux côtés.
- Jamais de `claude attach` hors d'un vrai terminal (il a répondu à une question le 04/11) : ni dans un test, ni par `Process`. Seul le terminal, via AppleScript, le lance.
- Le script AppleScript ne contient d'extérieur que le chemin de `claude` et l'identifiant du job ; shell fixe `/bin/zsh -lc '… ; exec /bin/zsh'`, jamais `$SHELL`.
- Clés `UserDefaults` nouvelles : `terminal.suivi` (Bool, absent = true), `terminal.app` (`"iterm"` ou `"terminal"`, absent = iTerm2 si installé sinon Terminal).
- `make install` uniquement depuis le dépôt principal, après la fusion.

## Points de vigilance

Les entrées que la spec implique et le test qui les tient :

- **Un `job` forgé dans un fichier (`../x`, `a; rm -rf ~`)** : n'atteint jamais le script. *Tâche 2 · `aMalformedJobOrTerminalIsIgnored` ; tâche 2 · `theScriptOnlyContainsThePathAndTheId`*
- **Suivi désactivé alors qu'une Desktop et un job attendent** : la Desktop garde sa bulle « ! », le job compte comme travail. *Tâche 3 · `withTrackingOffADesktopWaitStillWins`*
- **Un fichier qui a `lien` et `job`** (un agent de fond relancé depuis Desktop) : le lien gagne. *Tâche 3 · `theLinkWinsOverTheJob`*
- **Un ancien fichier sans les nouveaux champs, ou avec `terminal: "vscode"`** : se lit comme avant, sans cible terminal. *Tâche 2 · `theNewFieldsAreOptional`, `aMalformedJobOrTerminalIsIgnored`*
- **Le terminal de la conversation ne tourne plus, ou `claude` est introuvable** : le clic saute (et montre Claude pour `attach`), sans planter. *Tâche 4 · vérification à la main, lignes 6 et 7*

---

### Tâche 1 : Le mod écrit `job` et `terminal`

**Files :**
- Modify: `mod/hooks/state.ts`
- Modify: `mod/hooks/register.ts:49-53` (`writeState`)
- Test: `tests/mod/hooks/state.test.ts`, `tests/mod/hooks/register.test.ts`

**Interfaces :**
- Produces :
  - `export interface Origin { link?: string; job?: string; terminal?: string }`
  - `export function jobId(jobDir: string | undefined): string | undefined` — dernier segment du chemin, gardé seulement s'il vaut `^[0-9a-f]{8}$`.
  - `export function terminalName(termProgram: string | undefined): string | undefined` — `iTerm.app` ou `Apple_Terminal`, sinon `undefined`.
  - `export function sessionContent(state: State, ms: number, pid: number, origin: Origin): string` (remplace le paramètre `link`).

- [ ] **Step 1 : Préparer le worktree**

Run : `cd .worktrees/feat-terminal-conversations && ln -s /Users/berengerouadi/WorkingLab/personal/pokepet/sprites sprites && make test`
Expected : tout passe (état de départ).

- [ ] **Step 2 : Écrire les tests du module pur**

Dans `tests/mod/hooks/state.test.ts`, remplacer les deux tests de `sessionContent` et ajouter :

```ts
test('l’identifiant du job vient du dernier segment de CLAUDE_JOB_DIR', () => {
  expect(jobId('/Users/moi/.claude/jobs/c5adc286')).toBe('c5adc286')
  expect(jobId('/Users/moi/.claude/jobs/c5adc286/')).toBe('c5adc286')
})

test('un identifiant de job d’une autre forme n’est pas écrit', () => {
  expect(jobId(undefined)).toBe(undefined)
  expect(jobId('/jobs/C5ADC286')).toBe(undefined)
  expect(jobId('/jobs/../x')).toBe(undefined)
  expect(jobId('/jobs/c5adc286; rm -rf ~')).toBe(undefined)
  expect(jobId('/jobs/c5adc28')).toBe(undefined)
})

test('seuls iTerm et Terminal sont des terminaux connus', () => {
  expect(terminalName('iTerm.app')).toBe('iTerm.app')
  expect(terminalName('Apple_Terminal')).toBe('Apple_Terminal')
  expect(terminalName('vscode')).toBe(undefined)
  expect(terminalName(undefined)).toBe(undefined)
})

test('le contenu est celui que l’app Swift lit (SessionStateTests)', () => {
  const ms = Date.UTC(2026, 9, 15, 14, 2, 11, 456)
  expect(sessionContent('attend', ms, 68387, { link: 'claude://code/continue?session=local_00000000-0000-4000-8000-000000000000' })).toBe(
    '{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":68387,"lien":"claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"}')
  expect(sessionContent('attend', Date.UTC(2026, 10, 3, 14, 13, 34), 87344, { job: 'c5adc286' })).toBe(
    '{"etat":"attend","majLe":"2026-11-03T14:13:34Z","pid":87344,"job":"c5adc286"}')
  expect(sessionContent('attend', Date.UTC(2026, 10, 4, 9, 0, 0), 12345, { terminal: 'iTerm.app' })).toBe(
    '{"etat":"attend","majLe":"2026-11-04T09:00:00Z","pid":12345,"terminal":"iTerm.app"}')
})

test('sans origine, aucun champ de plus', () => {
  expect(sessionContent('fini', Date.UTC(2026, 9, 15, 14, 2, 11), 1, {})).toBe(
    '{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}')
})
```

Dans `tests/mod/hooks/register.test.ts`, donner à `world` une option `env?: Record<string, string>` fusionnée dans `mock.env`, et ajouter :

```ts
test('un agent de fond écrit son identifiant de job, sans lien', async ($, on) => {
  const w = world(on, { entrypoint: 'cli', env: { CLAUDE_JOB_DIR: '/home/.claude/jobs/c5adc286' } })
  await $.turn.start({ text: 'salut', turnId: 't1' })
  expect(w.state()).toEqual({ etat: 'travaille', majLe: expect.any(String), pid: 4242, job: 'c5adc286' })
})

test('un claude lancé dans iTerm écrit son terminal', async ($, on) => {
  const w = world(on, { entrypoint: 'cli', env: { TERM_PROGRAM: 'iTerm.app' } })
  await $.turn.start({ text: 'salut', turnId: 't1' })
  expect(w.state()).toEqual({ etat: 'travaille', majLe: expect.any(String), pid: 4242, terminal: 'iTerm.app' })
})

test('une conversation Desktop garde son lien, même avec un TERM_PROGRAM', async ($, on) => {
  const w = world(on, { env: { TERM_PROGRAM: 'Apple_Terminal' } })
  await $.turn.start({ text: 'salut', turnId: 't1' })
  expect(w.state()).toEqual({ etat: 'travaille', majLe: expect.any(String), pid: 4242, lien: LINK, terminal: 'Apple_Terminal' })
})
```

- [ ] **Step 3 : Vérifier que les tests échouent**

Run : `make test-mod`
Expected : FAIL (`jobId`, `terminalName` inexistants ; `sessionContent` refuse l'objet).

- [ ] **Step 4 : Implémenter `jobId`, `terminalName`, `Origin` et le nouveau `sessionContent` dans `mod/hooks/state.ts`**

`sessionContent` n'ajoute une clé que si sa valeur est définie, dans l'ordre `lien`, `job`, `terminal`. Mettre à jour le commentaire de tête (« les valeurs et les clés restent en français »).

- [ ] **Step 5 : Faire lire l'environnement par `writeState` dans `mod/hooks/register.ts`**

`const origin: Origin = { link: desktopLink(await $.env.get('CLAUDE_CODE_HOST_SESSION_ID')), job: jobId(await $.env.get('CLAUDE_JOB_DIR')), terminal: terminalName(await $.env.get('TERM_PROGRAM')) }`. Tout ce qui touche `$` reste dans ce fichier (contrainte Desktop 2.1.295).

- [ ] **Step 6 : Vérifier que les tests passent, avec le Claude Code de Desktop aussi**

Run : `make test-mod`
Expected : PASS, y compris la ligne « Avec le Claude Code de Desktop ».

- [ ] **Step 7 : Commit**

```bash
git add mod/hooks/state.ts mod/hooks/register.ts tests/mod/hooks/state.test.ts tests/mod/hooks/register.test.ts
git commit -m "feat(mod): record the background job id and the terminal of a conversation"
```

---

### Tâche 2 : `TerminalApp` et les deux champs dans `SessionState`

**Files :**
- Create: `app/PokepetCore/TerminalApp.swift`
- Modify: `app/PokepetCore/SessionState.swift`
- Test: `tests/app/PokepetCore/TerminalAppTests.swift` (nouveau), `tests/app/PokepetCore/SessionStateTests.swift`

**Interfaces :**
- Produces :
  - `public enum TerminalApp: String, CaseIterable, Sendable { case iterm = "iterm", terminal = "terminal" }` (la valeur brute est la clé de préférence)
  - `public init?(termProgram: String)` — `"iTerm.app"` → `.iterm`, `"Apple_Terminal"` → `.terminal`, sinon `nil`
  - `public var bundleID: String` — `com.googlecode.iterm2`, `com.apple.Terminal`
  - `public var displayName: String` — `"iTerm2"`, `"Terminal"`
  - `public func attachScript(claudePath: String, job: String) -> String` — le script AppleScript de la spec § 2.2, en une chaîne
  - `SessionState.job: String?`, `SessionState.terminal: TerminalApp?` ; `init(status:updatedAt:pid:link:job:terminal:)` avec `nil` par défaut pour les trois derniers

- [ ] **Step 1 : Écrire les tests de `TerminalApp`**

```swift
import Testing
@testable import PokepetCore

@Test("TERM_PROGRAM désigne un terminal connu, ou rien", arguments: [
    ("iTerm.app", TerminalApp.iterm), ("Apple_Terminal", .terminal), ("vscode", nil), ("", nil),
])
func termProgramNamesAKnownTerminal(value: String, expected: TerminalApp?) {
    #expect(TerminalApp(termProgram: value) == expected)
}

@Test("chaque terminal a son bundle et son nom")
func eachTerminalHasItsBundleAndName() {
    #expect(TerminalApp.iterm.bundleID == "com.googlecode.iterm2" && TerminalApp.iterm.displayName == "iTerm2")
    #expect(TerminalApp.terminal.bundleID == "com.apple.Terminal" && TerminalApp.terminal.displayName == "Terminal")
}

@Test("le script ne contient d'extérieur que le chemin et l'identifiant")
func theScriptOnlyContainsThePathAndTheId() {
    let command = "/bin/zsh -lc '/Users/moi/.local/bin/claude attach c5adc286; exec /bin/zsh'"
    #expect(TerminalApp.iterm.attachScript(claudePath: "/Users/moi/.local/bin/claude", job: "c5adc286") ==
        "tell application \"iTerm\"\n  activate\n  create window with default profile command \"\(command)\"\nend tell")
    #expect(TerminalApp.terminal.attachScript(claudePath: "/Users/moi/.local/bin/claude", job: "c5adc286") ==
        "tell application \"Terminal\"\n  activate\n  do script \"\(command)\"\nend tell")
}
```

- [ ] **Step 2 : Écrire les tests de `SessionState`**

```swift
@Test("lit le job et le terminal écrits par le mod")
func readsTheJobAndTheTerminalWrittenByTheMod() throws {
    // The same texts as in the mod's test (tests/mod/hooks/state.test.ts).
    let job = try #require(SessionState.decode(Data(#"{"etat":"attend","majLe":"2026-11-03T14:13:34Z","pid":87344,"job":"c5adc286"}"#.utf8)))
    #expect(job.job == "c5adc286" && job.terminal == nil && job.link == nil)
    let term = try #require(SessionState.decode(Data(#"{"etat":"attend","majLe":"2026-11-04T09:00:00Z","pid":12345,"terminal":"iTerm.app"}"#.utf8)))
    #expect(term.terminal == .iterm && term.job == nil)
}

@Test("les nouveaux champs sont facultatifs")
func theNewFieldsAreOptional() throws {
    let s = try #require(SessionState.decode(Data(#"{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}"#.utf8)))
    #expect(s.job == nil && s.terminal == nil)
}

@Test("un job ou un terminal d'une autre forme est ignoré, le fichier reste lu", arguments: [
    #""job":"../x""#, #""job":"c5adc286; rm -rf ~""#, #""job":"C5ADC286""#, #""job":7"#, #""terminal":"vscode""#, #""terminal":3"#,
])
func aMalformedJobOrTerminalIsIgnored(field: String) throws {
    let text = #"{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":1,"# + field + "}"
    let s = try #require(SessionState.decode(Data(text.utf8)))
    #expect(s.status == .waiting && s.job == nil && s.terminal == nil)
}
```

- [ ] **Step 3 : Vérifier qu'ils échouent**

Run : `make test-app FILTER=TerminalApp` puis `make test-app FILTER=SessionState`
Expected : erreur de compilation (`TerminalApp` inconnu, `job` inconnu).

- [ ] **Step 4 : Créer `app/PokepetCore/TerminalApp.swift`**

Les chaînes exactes de l'interface ci-dessus ; `attachScript` assemble `"/bin/zsh -lc '\(claudePath) attach \(job); exec /bin/zsh'"` puis le `tell` propre à chaque cas.

- [ ] **Step 5 : Ajouter `job` et `terminal` à `SessionState`**

Un `init(from decoder:)` écrit à la main : les quatre champs existants comme avant, puis `decodeIfPresent(String.self, forKey: .job)` gardé seulement s'il vérifie `^[0-9a-f]{8}$` (`wholeMatch(of: /[0-9a-f]{8}/)`), et `decodeIfPresent(String.self, forKey: .terminal)` passé dans `TerminalApp(termProgram:)`. Un champ du mauvais type (`"job":7`) donne `nil` sans faire échouer le décodage (`try?` sur ce seul champ). `SessionState` n'a plus besoin de `Codable` en écriture : garder `Decodable` seulement si `Encodable` ne sert nulle part (vérifier par `grep -rn "JSONEncoder" app tests`).

- [ ] **Step 6 : Vérifier que tout passe**

Run : `make test-app`
Expected : PASS.

- [ ] **Step 7 : Commit**

```bash
git add app/PokepetCore/TerminalApp.swift app/PokepetCore/SessionState.swift tests/app/PokepetCore/TerminalAppTests.swift tests/app/PokepetCore/SessionStateTests.swift
git commit -m "feat(core): read the job and terminal of a session, describe the two terminals"
```

---

### Tâche 3 : La cible, la bulle « >_ » et le clic

**Files :**
- Modify: `app/PokepetCore/MostUrgentState.swift`
- Modify: `app/PokepetCore/ClickRule.swift`
- Modify: `app/PokepetCore/Companion.swift` (`Appearance.bubble`, `Appearance.target`)
- Modify: `app/Pokepote/SpriteView.swift` (`bubble: Bubble`, `drawBubble`)
- Modify: `app/Pokepote/ConversationOpener.swift`
- Modify: `app/Pokepote/Loops.swift:79-81` (`view.bubble`), `:268-278` (`click()`)
- Test: `tests/app/PokepetCore/MostUrgentStateTests.swift`, `ClickRuleTests.swift`, `CompanionTests.swift`

**Interfaces :**
- Consumes : `SessionState.job`, `.terminal`, `TerminalApp` (tâche 2).
- Produces :
  - `public enum ClickTarget: Equatable, Sendable { case desktop(String), job(String), terminal(TerminalApp) }`
  - `public struct Urgency { public let display: DisplayState; public let target: ClickTarget?; init(display:target:) }` (`link` disparaît)
  - `MostUrgentState.compute(_ sessions: [SessionState], terminalTracking: Bool = true) -> Urgency`
  - `static func target(of session: SessionState) -> ClickTarget?` — `lien` de forme acceptée, sinon `job`, sinon `terminal`, sinon `nil`
  - `public enum Bubble: Equatable, Sendable { case none, exclamation, terminal }`
  - `Appearance.bubble: Bubble`, `Appearance.target: ClickTarget?` (`link` disparaît)
  - `public enum ClickAction { case openConversation(String), attachJob(String, in: TerminalApp), showTerminal(TerminalApp), hopAndShowClaude, hop }`
  - `ClickRule.action(target: ClickTarget?, terminalApp: TerminalApp, claudeIsFrontmost: Bool) -> ClickAction`
  - `ConversationOpener.attach(job: String, in app: TerminalApp) -> Bool` (faux : pas de `claude`, ou `NSAppleScript` en erreur ; l'erreur est journalisée par `AppDelegate.log`)
  - `ConversationOpener.show(_ app: TerminalApp) -> Bool` (faux si le terminal ne tourne pas)
  - `ConversationOpener.claudePath: String?` — premier existant parmi `~/.local/bin/claude`, `/opt/homebrew/bin/claude`, `/usr/local/bin/claude`
  - `ConversationOpener.defaultTerminal: TerminalApp` — `.iterm` si `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` le trouve, sinon `.terminal`

- [ ] **Step 1 : Réécrire les tests de `MostUrgentState`**

Le fabricant `s(…)` prend `link:`, `job:`, `terminal:` ; `linkComesFromTheWaitingSession` compare à `Urgency(display: .waiting, target: .desktop(linkB))` ; `aWaitWithoutLinkGivesNoLink` et `unexpectedLinkIsNeverOpened` lisent `.target == nil`. Remplacer `betweenTwoWaitsTheMostRecentWithALinkWins` et ajouter :

```swift
@Test("entre plusieurs attentes, la plus récente gagne, quelle que soit sa cible")
func betweenSeveralWaitsTheMostRecentWins() {
    let u = MostUrgentState.compute([s(.waiting, 10, link: linkA), s(.waiting, 30, job: "c5adc286"), s(.waiting, 20, terminal: .iterm)])
    #expect(u.target == .job("c5adc286"))
    #expect(MostUrgentState.compute([s(.waiting, 10, job: "c5adc286"), s(.waiting, 20)]).target == nil)
}

@Test("la cible se lit dans l'ordre lien, job, terminal")
func theLinkWinsOverTheJob() {
    #expect(MostUrgentState.target(of: s(.waiting, link: linkA, job: "c5adc286", terminal: .iterm)) == .desktop(linkA))
    #expect(MostUrgentState.target(of: s(.waiting, link: "https://exemple.com", job: "c5adc286", terminal: .iterm)) == .job("c5adc286"))
    #expect(MostUrgentState.target(of: s(.waiting, terminal: .terminal)) == .terminal(.terminal))
}

@Test("suivi désactivé : une attente terminal compte comme travail")
func withTrackingOffATerminalWaitCountsAsWork() {
    #expect(MostUrgentState.compute([s(.waiting, job: "c5adc286")], terminalTracking: false) == Urgency(display: .working, target: nil))
    #expect(MostUrgentState.compute([s(.waiting, terminal: .iterm)], terminalTracking: false).display == .working)
    #expect(MostUrgentState.compute([s(.waiting)], terminalTracking: false).display == .working)
}

@Test("suivi désactivé : une attente Desktop garde sa bulle")
func withTrackingOffADesktopWaitStillWins() {
    let u = MostUrgentState.compute([s(.waiting, 10, link: linkA), s(.waiting, 20, job: "c5adc286")], terminalTracking: false)
    #expect(u == Urgency(display: .waiting, target: .desktop(linkA)))
}
```

- [ ] **Step 2 : Réécrire les tests de `ClickRule`**

```swift
private let link = "claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"

@Test func aWaitingDesktopConversationIsOpened() {
    #expect(ClickRule.action(target: .desktop(link), terminalApp: .iterm, claudeIsFrontmost: false) == .openConversation(link))
    #expect(ClickRule.action(target: .desktop(link), terminalApp: .iterm, claudeIsFrontmost: true) == .openConversation(link))
}

@Test func aWaitingBackgroundJobIsAttachedInTheChosenTerminal() {
    #expect(ClickRule.action(target: .job("c5adc286"), terminalApp: .terminal, claudeIsFrontmost: true) == .attachJob("c5adc286", in: .terminal))
}

@Test func aWaitingTerminalConversationBringsItsTerminalForward() {
    #expect(ClickRule.action(target: .terminal(.iterm), terminalApp: .terminal, claudeIsFrontmost: false) == .showTerminal(.iterm))
}

@Test func withoutAWaitingConversationItHopsAndBringsClaudeForward() {
    #expect(ClickRule.action(target: nil, terminalApp: .iterm, claudeIsFrontmost: false) == .hopAndShowClaude)
}

@Test func whenClaudeIsAlreadyInFrontItOnlyHops() {
    #expect(ClickRule.action(target: nil, terminalApp: .iterm, claudeIsFrontmost: true) == .hop)
}
```

- [ ] **Step 3 : Adapter les tests du compagnon**

Dans `CompanionTests.swift`, l'aide `update(&c, display, link:)` devient `update(&c, display, target: ClickTarget? = nil)` et construit `Urgency(display:target:)`. Remplacer `bubbleAndLinkOnlyWhenAConversationWaits` par :

```swift
@Test("la bulle « ! » pour Desktop, « >_ » pour un job ou un terminal, rien sinon")
func theBubbleTellsWhereTheConversationIs() {
    var c = Companion(launchDate: t0)
    let desktop = update(&c, .waiting, target: .desktop(linkA))
    #expect(desktop.bubble == .exclamation && desktop.target == .desktop(linkA))
    #expect(update(&c, .waiting, target: .job("c5adc286")).bubble == .terminal)
    #expect(update(&c, .waiting, target: .terminal(.iterm)).bubble == .terminal)
    #expect(update(&c, .waiting).bubble == .exclamation)
    #expect(update(&c, .working).bubble == .none)
}
```

`startingToWaitMakesThreeHops` gagne une ligne : après `_ = update(&c, .working)`, `#expect(update(&c, .waiting, target: .job("c5adc286")).interlude == Interlude(movement: .hop, times: 3))`.

- [ ] **Step 4 : Vérifier qu'ils échouent**

Run : `make test-app FILTER=MostUrgentState`
Expected : erreur de compilation (`target`, `ClickTarget`).

- [ ] **Step 5 : Implémenter `ClickTarget`, `Urgency.target`, `MostUrgentState.compute(_:terminalTracking:)` et `target(of:)`**

Avec le suivi désactivé, une session `attend` dont `target(of:)` n'est pas `.desktop` s'affiche `.working`. La cible retenue : celle de la session `attend` la plus récente (`updatedAt`) parmi celles encore affichées `.waiting`. `isAccepted` ne change pas.

- [ ] **Step 6 : Implémenter `Bubble` et `Appearance.target` dans `Companion.swift`, puis `ClickRule`**

`bubble` : `.none` hors attente ; `.terminal` si la cible est `.job` ou `.terminal` ; `.exclamation` sinon.

- [ ] **Step 7 : Dessiner « >_ » dans `SpriteView`**

`var bubble: Bubble = .none` (même `didSet`). `drawBubble` garde le cercle et dessine, selon le cas : « ! » comme aujourd'hui, ou `">_"` en `NSFont.monospacedSystemFont(ofSize: radius * 1.0, weight: .bold)`, `NSColor.systemBlue`, centré de la même façon. `draw(_:)` appelle `drawBubble()` si `bubble != .none` ; la zone cliquable (`hitTest`) teste de même.

- [ ] **Step 8 : Implémenter `ConversationOpener.attach(job:in:)`, `show(_:)`, `claudePath`, `defaultTerminal`**

`attach` : `guard let claudePath` sinon faux ; `NSAppleScript(source: app.attachScript(claudePath:job:))`, `executeAndReturnError(&error)` ; en cas d'erreur, `AppDelegate.log("attach \(job) dans \(app.displayName) : \(error ?? [:])")` et faux. `show` : `NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID).first?.activate()`, faux si aucune.

- [ ] **Step 9 : Brancher `Loops`**

`reload()` : `MostUrgentState.compute(sessions)` (le réglage arrive à la tâche 4) et `view.bubble = next.bubble`. `click()` : `ClickRule.action(target: appearance?.target, terminalApp: ConversationOpener.defaultTerminal, claudeIsFrontmost:)` ; `.attachJob` → si `attach` rend faux, `play(.hop, times: 1)` et `showClaude()` ; `.showTerminal` → si `show` rend faux, `play(.hop, times: 1)`. Pas de saut quand l'`attach` part : le terminal arrive devant, comme pour Desktop.

- [ ] **Step 10 : Vérifier que tout passe et que l'app compile**

Run : `make test-app` puis `swift build --build-system native`
Expected : PASS ; build sans erreur ni warning nouveau.

- [ ] **Step 11 : Commit**

```bash
git add app/PokepetCore/MostUrgentState.swift app/PokepetCore/ClickRule.swift app/PokepetCore/Companion.swift app/Pokepote/SpriteView.swift app/Pokepote/ConversationOpener.swift app/Pokepote/Loops.swift tests/app/PokepetCore/MostUrgentStateTests.swift tests/app/PokepetCore/ClickRuleTests.swift tests/app/PokepetCore/CompanionTests.swift
git commit -m "feat(app): show a terminal bubble and open the waiting terminal conversation on click"
```

---

### Tâche 4 : Les deux réglages

**Files :**
- Modify: `app/PokepetCore/Preferences.swift`
- Modify: `app/Pokepote/Loops.swift` (`reload()`, deux propriétés), `app/Pokepote/PopoverModel.swift`, `app/Pokepote/SettingsTab.swift`
- Test: `tests/app/PokepetCore/PreferencesTests.swift`

**Interfaces :**
- Consumes : `TerminalApp` (tâche 2), `MostUrgentState.compute(_:terminalTracking:)`, `ConversationOpener.defaultTerminal` (tâche 3).
- Produces :
  - `Preferences.terminalTracking: Bool` (clé `terminal.suivi`, absent = `true`)
  - `Preferences.terminalApp: TerminalApp?` (clé `terminal.app`, valeur brute ; absent ou inconnu = `nil`)
  - `Loops.terminalTracking: Bool { get set }` (écrit la préférence et relance `reload()`), `Loops.terminalApp: TerminalApp { get set }` (`nil` en préférence → `ConversationOpener.defaultTerminal`)
  - `PopoverModel.terminalTracking: Bool`, `PopoverModel.terminalApp: TerminalApp`, rafraîchis dans `refresh()` et propagés à `Loops` dans leur `didSet`, comme `companionVisible`

- [ ] **Step 1 : Écrire les tests de `Preferences`**

```swift
@Test("le suivi des conversations terminal est actif par défaut, et son arrêt est retenu")
func terminalTrackingIsOnByDefaultAndRemembered() {
    let (p, _) = blankPreferences()
    #expect(p.terminalTracking)
    p.terminalTracking = false
    #expect(!p.terminalTracking)
}

@Test("le terminal choisi est retenu ; absent ou inconnu, il n'y en a pas")
func theChosenTerminalIsRemembered() {
    let (p, defaults) = blankPreferences()
    #expect(p.terminalApp == nil)
    p.terminalApp = .terminal
    #expect(p.terminalApp == .terminal && defaults.string(forKey: "terminal.app") == "terminal")
    defaults.set("ghostty", forKey: "terminal.app")
    #expect(p.terminalApp == nil)
}
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run : `make test-app FILTER=Preferences`
Expected : erreur de compilation.

- [ ] **Step 3 : Implémenter les deux propriétés dans `Preferences`**

Même style que `companionVisible` (`defaults.object(forKey:) == nil` pour le défaut) et que `dailyChoice` (`.flatMap(TerminalApp.init(rawValue:))`).

- [ ] **Step 4 : Brancher `Loops`, `PopoverModel` et `SettingsTab`**

`Loops.reload()` passe `terminalTracking: preferences.terminalTracking` ; `click()` prend `terminalApp` au lieu de `ConversationOpener.defaultTerminal`. Dans `SettingsTab`, sous le `HStack` de la taille :

```swift
Toggle("Suivre les conversations terminal", isOn: $model.terminalTracking).toggleStyle(.switch)
Picker("Terminal", selection: $model.terminalApp) {
    ForEach(TerminalApp.allCases, id: \.self) { Text($0.displayName).tag($0) }
}
.pickerStyle(.menu)
.disabled(!model.terminalTracking)
```

- [ ] **Step 5 : Vérifier, compiler, essayer**

Run : `make test-app` puis `make run`
Expected : PASS ; dans la fenêtre de la barre des menus, onglet Réglages, le toggle et le sélecteur (grisé quand le toggle est éteint) ; `defaults read com.hn6pot.pokepote` montre `terminal.suivi` et `terminal.app` après un changement. Quitter l'app lancée par `make run` (Ctrl-C).

- [ ] **Step 6 : Commit**

```bash
git add app/PokepetCore/Preferences.swift app/Pokepote/Loops.swift app/Pokepote/PopoverModel.swift app/Pokepote/SettingsTab.swift tests/app/PokepetCore/PreferencesTests.swift
git commit -m "feat(app): settings to follow terminal conversations and pick the terminal"
```

---

### Tâche 5 : Permission AppleScript, vérification à la main, docs et PR

**Files :**
- Modify: `packaging/Info.plist`
- Create: `docs/verifications/2026-11-05-conversations-terminal.md`
- Modify: `README.md:8`, `README.md:53`, `docs/specs/2026-10-15-pokepet-design.md` (§ 3 et « Gestes »)

- [ ] **Step 1 : Déclarer l'usage des événements Apple**

Dans `packaging/Info.plist`, avant `LSUIElement` : clé `NSAppleEventsUsageDescription`, valeur `Poképote ouvre dans votre terminal la conversation Claude Code qui attend votre réponse.`

- [ ] **Step 2 : Construire le bundle et le lancer à la place de l'app installée**

Run :
```bash
make app && launchctl bootout gui/$(id -u)/com.hn6pot.pokepote; open .build/Poképote.app
```
Expected : le compagnon apparaît (sprites trouvés par le lien symbolique absolu). À la fin de la vérification : `osascript -e 'tell application "Poképote" to quit'; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.hn6pot.pokepote.plist` remet l'app installée.

- [ ] **Step 3 : Vérifier à la main et noter dans `docs/verifications/2026-11-05-conversations-terminal.md`**

Même tableau que `2026-10-15-mod-en-vrai.md` (situation, attendu, vu). Le mod à jour doit être celui du worktree : `claude plugin marketplace add "$PWD"` puis `claude plugin install pokepet@pokepet --scope user` depuis le worktree (le `make install` final le remettra depuis le dépôt principal). Lignes :

| # | Situation | Attendu |
|---|---|---|
| 1 | Dans iTerm, `claude --bg` sur un dossier de test, puis `claude attach <id>` et une question (« pose-moi une question avec AskUserQuestion ») ; se détacher | fichier avec `job`, bulle « >_ » |
| 2 | Clic sur « >_ », réglage iTerm2 | macOS demande la permission une fois ; iTerm ouvre une fenêtre, le job apparaît avec sa question |
| 3 | Répondre dans cette fenêtre | la bulle disparaît ; la fenêtre reste ouverte sur un shell |
| 4 | Même scénario, réglage Terminal | Terminal ouvre une fenêtre, le job apparaît |
| 5 | Second clic sur « >_ » alors que le job est déjà attaché | **noter ce qui se passe** (deuxième vue, refus, reprise) ; décider s'il faut une détection (spec § 5) |
| 6 | Un job archivé : clic sur « >_ » après `claude stop <id>` (le fichier reste tant que le pid vit : prendre un pid encore vivant, ou simuler un fichier `job` d'un identifiant inconnu avec le pid de l'app) | la fenêtre reste ouverte avec l'erreur d'`attach` lisible |
| 7 | `claude` lancé à la main dans iTerm, une question | fichier avec `terminal: "iTerm.app"`, bulle « >_ », clic = iTerm au premier plan (iTerm fermé entre-temps : le compagnon saute seulement) |
| 8 | Conversation Desktop, une question | bulle « ! », clic ouvre Desktop : inchangé |
| 9 | Suivi désactivé, job en attente | plus de « >_ », le Pokémon travaille ; une Desktop en attente garde « ! » |
| 10 | `claude` introuvable (renommer `~/.local/bin/claude` le temps d'un clic, si c'est le seul chemin) | le compagnon saute et montre Claude ; une ligne dans le journal |

- [ ] **Step 4 : Mettre à jour la doc**

`README.md` ligne 8 : ajouter « or with a “>_” bubble when the waiting conversation runs in a terminal » ; ligne 53 : « opens the waiting conversation (desktop app), or, for a background `claude --bg` job, opens your terminal of choice with `claude attach` on it (Settings tab) ». Spec principale : § 3 (« `lien` : absent hors Desktop ») et le paragraphe « Gestes » renvoient à `2026-11-04-terminal-conversations-design.md`. Si la ligne 5 du tableau a montré un désagrément, l'écrire au § 4 de la nouvelle spec (statut : « construite », avec la date).

- [ ] **Step 5 : Tout relancer**

Run : `make test`
Expected : PASS (app et mod, Desktop compris).

- [ ] **Step 6 : Commit, push, PR**

```bash
git add packaging/Info.plist docs/verifications/2026-11-05-conversations-terminal.md README.md docs/specs/2026-10-15-pokepet-design.md docs/specs/2026-11-04-terminal-conversations-design.md
git commit -m "docs: verify the terminal bubble by hand and point the main spec to it"
git -c credential.https://github.com.helper= -c "credential.https://github.com.helper=!GH_CONFIG_DIR=$HOME/.config/gh-hn6pot gh auth git-credential" push -u origin feat/terminal-conversations
GH_CONFIG_DIR=~/.config/gh-hn6pot gh pr create --title "feat: open a waiting terminal conversation from the bubble" --body-file "$SCRATCHPAD/pr-body.md"
```

Corps de la PR (écrit d'abord dans `$SCRATCHPAD/pr-body.md`) : le pourquoi (l'agent « notion » bloqué 31 h), les trois lignes de la spec (bulle « >_ », clic, réglages), le lien de l'artefact de la spec, le tableau de vérification en résumé, et la ligne `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Puis attendre la relecture de Bérenger ; après son OK : merge, `git pull` dans le dépôt principal, `make install` depuis le dépôt principal, suppression du worktree et de la branche.
