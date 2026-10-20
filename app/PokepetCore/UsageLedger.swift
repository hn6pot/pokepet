import Foundation

/// What was counted for one origin on one day.
public struct UsageTotals: Codable, Equatable, Sendable {
    public var messages = 0
    public var output = 0
    public var cacheRead = 0
}

/// One day's totals, the user's conversations and the automatic runs apart.
public struct DayUsage: Codable, Equatable, Sendable {
    public var you = UsageTotals()
    public var automatic = UsageTotals()

    public subscript(origin: Origin) -> UsageTotals {
        get { origin == .you ? you : automatic }
        set { if origin == .you { you = newValue } else { automatic = newValue } }
    }
}

/// A reply already counted: where, and with how many tokens (the largest seen on its lines).
public struct CountedReply: Codable, Equatable, Sendable {
    public let day: String
    public let origin: Origin
    public let output: Int
    public let cacheRead: Int
}

/// The totals per Poképote day, kept in `~/.pokepet/usage.json`, with what is needed
/// to never count a line twice: how far each transcript was read, and the ids already counted.
public struct UsageLedger: Codable, Equatable, Sendable {
    public private(set) var days: [String: DayUsage] = [:]
    /// Transcript path → bytes already read.
    public var offsets: [String: Int] = [:]
    /// Reply `message.id` → what was counted for it.
    public private(set) var replies: [String: CountedReply] = [:]
    /// Typed message `uuid` → its day.
    public private(set) var messageDays: [String: String] = [:]

    public init() {}

    public mutating func record(_ entry: TranscriptEntry, calendar: Calendar = .current) {
        switch entry {
        case let .typedMessage(uuid, date, origin):
            guard messageDays[uuid] == nil else { return }
            let day = PokepetDay.key(date, calendar: calendar)
            messageDays[uuid] = day
            days[day, default: DayUsage()][origin].messages += 1
        case let .reply(id, date, origin, output, cacheRead):
            // The lines of one reply may carry a partial count first: keep the largest, add only the difference.
            let counted = replies[id] ?? CountedReply(
                day: PokepetDay.key(date, calendar: calendar), origin: origin, output: 0, cacheRead: 0)
            let newOutput = max(counted.output, output), newCacheRead = max(counted.cacheRead, cacheRead)
            days[counted.day, default: DayUsage()][counted.origin].output += newOutput - counted.output
            days[counted.day, default: DayUsage()][counted.origin].cacheRead += newCacheRead - counted.cacheRead
            replies[id] = CountedReply(day: counted.day, origin: counted.origin, output: newOutput, cacheRead: newCacheRead)
        }
    }

    public func day(_ key: String) -> DayUsage {
        days[key] ?? DayUsage()
    }

    /// The sum of the days whose key starts with `prefix` ("2026-10").
    public func month(_ prefix: String) -> DayUsage {
        days.filter { $0.key.hasPrefix(prefix) }.values.reduce(into: DayUsage()) { sum, day in
            for origin in [Origin.you, .automatic] {
                sum[origin].messages += day[origin].messages
                sum[origin].output += day[origin].output
                sum[origin].cacheRead += day[origin].cacheRead
            }
        }
    }

    /// Forgets the ids of the days before `day` ("YYYY-MM-DD"), so the file stays small; the totals stay.
    public mutating func forgetIDs(before day: String) {
        replies = replies.filter { $0.value.day >= day }
        messageDays = messageDays.filter { $0.value >= day }
    }

    /// An empty ledger if the file is missing or unreadable.
    public static func load(from url: URL) -> UsageLedger {
        (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(UsageLedger.self, from: $0) } ?? UsageLedger()
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }
}
