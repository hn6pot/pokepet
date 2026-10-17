import Foundation

/// What the mod writes about a conversation. The raw values are the file format shared with the mod
/// (and with the installed app): they stay in French.
public enum SessionStatus: String, Codable, Sendable {
    case working = "travaille"
    case waiting = "attend"
    case done = "fini"
    case failed = "echec"
    case closed = "fermee"
}

/// The content of a `~/.pokepet/sessions/<id>.json` file, written by the mod.
public struct SessionState: Codable, Equatable, Sendable {
    public let status: SessionStatus
    public let updatedAt: Date
    public let pid: Int32
    public let link: String?

    // The keys of the file written by the mod (mod/hooks/state.ts).
    enum CodingKeys: String, CodingKey {
        case status = "etat"
        case updatedAt = "majLe"
        case pid
        case link = "lien"
    }

    public init(status: SessionStatus, updatedAt: Date, pid: Int32, link: String? = nil) {
        self.status = status
        self.updatedAt = updatedAt
        self.pid = pid
        self.link = link
    }

    /// `nil` if the file is unreadable (broken JSON, missing field, unknown state).
    public static func decode(_ data: Data) -> SessionState? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SessionState.self, from: data)
    }
}
