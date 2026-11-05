import AppKit
import PokepetCore

/// Opens the waiting conversation: in the Claude app, in a terminal (`claude attach`), or by bringing a terminal forward.
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

    /// The terminal picked when none is set: iTerm2 if it is installed, Terminal otherwise.
    static var defaultTerminal: TerminalApp {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: TerminalApp.iterm.bundleID) == nil ? .terminal : .iterm
    }

    /// The `claude` binary, where the installers put it; `nil` if none is there.
    static var claudePath: String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [home + "/.local/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Opens `app` with `claude attach <job>` running in a new window, through AppleScript: the only way that
    /// works for iTerm, and the only safe one (an `attach` outside a real terminal answers the pending question).
    /// False if `claude` is missing or the script fails; the error goes to the log.
    static func attach(job: String, in app: TerminalApp) -> Bool {
        guard let claudePath else {
            AppDelegate.log("attach \(job) : binaire claude introuvable")
            return false
        }
        var error: NSDictionary?
        let script = NSAppleScript(source: app.attachScript(claudePath: claudePath, job: job))
        guard script?.executeAndReturnError(&error) != nil else {
            AppDelegate.log("attach \(job) dans \(app.displayName) : \(error ?? [:])")
            return false
        }
        return true
    }

    /// Brings a terminal to the front; false if it is not running.
    static func show(_ app: TerminalApp) -> Bool {
        guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID).first else { return false }
        running.activate()
        return true
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
