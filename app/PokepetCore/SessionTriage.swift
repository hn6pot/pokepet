import Foundation

/// What the app does with a session file.
public enum Decision: Equatable, Sendable {
    case keep, ignore, delete
}

/// The rules for reading session files (spec § 3).
public enum SessionTriage {
    public static let staleAfter: TimeInterval = 2 * 3600

    /// `session` is `nil` when the file is unreadable: it is ignored without being deleted
    /// (the mod may be writing it).
    public static func decide(
        _ session: SessionState?, now: Date, isPidAlive: (Int32) -> Bool
    ) -> Decision {
        guard let session else { return .ignore }
        if session.status == .closed || !isPidAlive(session.pid) { return .delete }
        if session.status != .waiting && now.timeIntervalSince(session.updatedAt) > staleAfter {
            return .ignore
        }
        return .keep
    }
}
