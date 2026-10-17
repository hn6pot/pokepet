import AppKit

/// Opens the waiting conversation in the Claude app.
/// The link has already been checked by `MostUrgentState` (claude://code/continue?session=local_…).
@MainActor
enum ConversationOpener {
    static func open(_ link: String) {
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
}
