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
public struct SessionState: Decodable, Equatable, Sendable {
    public let status: SessionStatus
    public let updatedAt: Date
    public let pid: Int32
    public let link: String?
    /// The short id of a background job (`claude --bg`), `^[0-9a-f]{8}$`: it ends up in a terminal command.
    public let job: String?
    /// The terminal the conversation runs in, when the app knows it.
    public let terminal: TerminalApp?

    // The keys of the file written by the mod (mod/hooks/state.ts).
    enum CodingKeys: String, CodingKey {
        case status = "etat"
        case updatedAt = "majLe"
        case pid
        case link = "lien"
        case job
        case terminal
    }

    public init(status: SessionStatus, updatedAt: Date, pid: Int32, link: String? = nil, job: String? = nil, terminal: TerminalApp? = nil) {
        self.status = status
        self.updatedAt = updatedAt
        self.pid = pid
        self.link = link
        self.job = job
        self.terminal = terminal
    }

    /// `job` and `terminal` of an unexpected form or type are dropped without failing the whole file:
    /// anything can write into ~/.pokepet.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decode(SessionStatus.self, forKey: .status)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        pid = try c.decode(Int32.self, forKey: .pid)
        link = try c.decodeIfPresent(String.self, forKey: .link)
        let rawJob = try? c.decodeIfPresent(String.self, forKey: .job)
        job = rawJob.flatMap { $0.wholeMatch(of: /[0-9a-f]{8}/) != nil ? $0 : nil }
        let rawTerminal = try? c.decodeIfPresent(String.self, forKey: .terminal)
        terminal = rawTerminal.flatMap(TerminalApp.init(termProgram:))
    }

    /// `nil` if the file is unreadable (broken JSON, missing field, unknown state).
    public static func decode(_ data: Data) -> SessionState? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SessionState.self, from: data)
    }
}
