import AppKit
import PokepetCore

/// Assembles the pieces at startup: preferences, sprites, window, gestures, loops.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var loops: Loops?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let directory = Self.spritesDirectory()
        guard FileManager.default.fileExists(atPath: directory.appending(path: "0004/AnimData.xml").path) else {
            Self.log("sprites introuvables dans \(directory.path)")
            exit(1)
        }
        let view = SpriteView()
        let window = CompanionWindow(view: view)
        let loops = Loops(
            window: window, view: view, sprites: PMDSprites(directory: directory),
            preferences: Preferences(defaults: .standard), stateDirectory: .standard)
        view.gestures = MouseGestures(window: window, view: view, loops: loops)
        loops.start()
        window.orderFrontRegardless()
        self.loops = loops
    }

    /// In the installed app: `Poképote.app/Contents/Resources/sprites/pmd`.
    /// With `make run`: the POKEPET_SPRITES variable points to the repository's `sprites/pmd`.
    private static func spritesDirectory() -> URL {
        if let path = ProcessInfo.processInfo.environment["POKEPET_SPRITES"] {
            return URL(filePath: path)
        }
        return Bundle.main.resourceURL!.appending(path: "sprites/pmd")
    }

    /// Appends a line to ~/.pokepet/pokepet.log.
    static func log(_ message: String) {
        let url = StateDirectory.standard.root.appending(path: "pokepet.log")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let line = Data("\(Date().ISO8601Format()) \(message)\n".utf8)
        if let file = try? FileHandle(forWritingTo: url) {
            file.seekToEndOfFile()
            file.write(line)
            try? file.close()
        } else {
            try? line.write(to: url)
        }
    }
}
