/// What a click on the pet does.
public enum ClickAction: Equatable, Sendable {
    /// A Desktop conversation is waiting: open it.
    case openConversation(String)
    /// Nothing to open: hop, and bring the Claude app to the front (launching it if needed).
    case hopAndShowClaude
    /// Claude is already in front: just hop.
    case hop
}

/// Decides what a click does, from the waiting conversation's link and whether Claude is the frontmost app.
public enum ClickRule {
    public static func action(link: String?, claudeIsFrontmost: Bool) -> ClickAction {
        if let link { return .openConversation(link) }
        return claudeIsFrontmost ? .hop : .hopAndShowClaude
    }
}
