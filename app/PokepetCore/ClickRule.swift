/// What a click on the pet does.
public enum ClickAction: Equatable, Sendable {
    /// A Desktop conversation is waiting: open it.
    case openConversation(String)
    /// A background job is waiting: open the chosen terminal with `claude attach <job>` in it.
    case attachJob(String, in: TerminalApp)
    /// A conversation in a terminal is waiting: bring that terminal to the front.
    case showTerminal(TerminalApp)
    /// Nothing to open: hop, and bring the Claude app to the front (launching it if needed).
    case hopAndShowClaude
    /// Claude is already in front: just hop.
    case hop
}

/// Decides what a click does, from the waiting conversation's target, the terminal picked in the settings,
/// and whether Claude is the frontmost app.
public enum ClickRule {
    public static func action(target: ClickTarget?, terminalApp: TerminalApp, claudeIsFrontmost: Bool) -> ClickAction {
        switch target {
        case .desktop(let link): return .openConversation(link)
        case .job(let job): return .attachJob(job, in: terminalApp)
        case .terminal(let app): return .showTerminal(app)
        case nil: return claudeIsFrontmost ? .hop : .hopAndShowClaude
        }
    }
}
