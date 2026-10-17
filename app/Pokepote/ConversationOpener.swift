import AppKit

/// Opens the waiting conversation in the Claude app, or simply brings the app forward.
@MainActor
enum ConversationOpener {
    /// The Claude desktop app.
    static let claudeBundleID = "com.anthropic.claudefordesktop"

    /// The link has already been checked by `MostUrgentState` (claude://code/continue?session=local_…).
    static func open(_ link: String) {
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }

    static var claudeIsFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == claudeBundleID
    }

    /// Brings the Claude app to the front, launching it if it is not running.
    static func showClaude() {
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: claudeBundleID).first {
            running.activate()
        } else if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: claudeBundleID) {
            NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}
