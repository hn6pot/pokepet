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

@Test("le script ne contient d'extérieur que le chemin et l'identifiant, et active le terminal après avoir ouvert la fenêtre")
func theScriptOnlyContainsThePathAndTheId() {
    // `activate` last: a terminal that was not running would otherwise open its default window too.
    let command = "/bin/zsh -lc '/Users/moi/.local/bin/claude attach c5adc286; exec /bin/zsh'"
    #expect(TerminalApp.iterm.attachScript(claudePath: "/Users/moi/.local/bin/claude", job: "c5adc286") ==
        "tell application \"iTerm\"\n  create window with default profile command \"\(command)\"\n  activate\nend tell")
    #expect(TerminalApp.terminal.attachScript(claudePath: "/Users/moi/.local/bin/claude", job: "c5adc286") ==
        "tell application \"Terminal\"\n  do script \"\(command)\"\n  activate\nend tell")
}
