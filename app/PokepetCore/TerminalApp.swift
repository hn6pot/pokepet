/// The two terminals the app knows: where a conversation runs, and where a background job gets attached.
/// The raw value is the preference key (`terminal.app`).
public enum TerminalApp: String, CaseIterable, Sendable {
    case iterm = "iterm"
    case terminal = "terminal"

    /// From `TERM_PROGRAM`, as the mod writes it; `nil` for any other terminal.
    public init?(termProgram: String) {
        switch termProgram {
        case "iTerm.app": self = .iterm
        case "Apple_Terminal": self = .terminal
        default: return nil
        }
    }

    public var bundleID: String {
        switch self {
        case .iterm: "com.googlecode.iterm2"
        case .terminal: "com.apple.Terminal"
        }
    }

    public var displayName: String {
        switch self {
        case .iterm: "iTerm2"
        case .terminal: "Terminal"
        }
    }

    /// The AppleScript that opens a window running `claude attach <job>`, through a shell that stays open
    /// afterwards (iTerm closes the window as soon as the command ends, and an `attach` that fails would vanish
    /// before its error can be read). `claudePath` and `job` are the only values from outside; the caller has
    /// checked their form (`job` matches ^[0-9a-f]{8}$).
    public func attachScript(claudePath: String, job: String) -> String {
        let command = "/bin/zsh -lc '\(claudePath) attach \(job); exec /bin/zsh'"
        switch self {
        case .iterm:
            return "tell application \"iTerm\"\n  activate\n  create window with default profile command \"\(command)\"\nend tell"
        case .terminal:
            return "tell application \"Terminal\"\n  activate\n  do script \"\(command)\"\nend tell"
        }
    }
}
