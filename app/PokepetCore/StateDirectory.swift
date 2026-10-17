import Darwin
import Foundation

/// Reads `~/.pokepet/`: the sessions (deleting the doomed files) and the day's counters.
public struct StateDirectory: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public static var standard: StateDirectory {
        StateDirectory(root: FileManager.default.homeDirectoryForCurrentUser.appending(path: ".pokepet"))
    }

    /// The sessions to take into account; deletes along the way those that `SessionTriage` dooms.
    public func sessions(now: Date, isPidAlive: (Int32) -> Bool = StateDirectory.isPidAlive) -> [SessionState] {
        jsonFiles(in: root.appending(path: "sessions")).compactMap { url in
            let session = (try? Data(contentsOf: url)).flatMap(SessionState.decode)
            switch SessionTriage.decide(session, now: now, isPidAlive: isPidAlive) {
            case .keep: return session
            case .ignore: return nil
            case .delete:
                try? FileManager.default.removeItem(at: url)
                return nil
            }
        }
    }

    /// The raw content of the `jour/<day>/*.json` files; empty if the directory does not exist.
    public func counters(day: String) -> [Data] {
        jsonFiles(in: root.appending(path: "jour").appending(path: day))
            .compactMap { try? Data(contentsOf: $0) }
    }

    /// True if a process has this number (EPERM: it exists but belongs to another user).
    public static func isPidAlive(_ pid: Int32) -> Bool {
        pid > 0 && (kill(pid, 0) == 0 || errno == EPERM)
    }

    private func jsonFiles(in directory: URL) -> [URL] {
        let content = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return content.filter { $0.pathExtension == "json" }
    }
}
