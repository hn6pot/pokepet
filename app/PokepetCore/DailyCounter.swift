import Foundation

/// Adds up the day's responses, one conversation per file `{ "reponses": 12 }`.
public enum DailyCounter {
    private struct CounterFile: Decodable {
        let responses: Int

        // The mod's file format, shared with the installed app: its keys stay as they are.
        enum CodingKeys: String, CodingKey {
            case responses = "reponses"
        }
    }

    /// An unreadable or negative file counts as zero.
    public static func total(_ files: [Data]) -> Int {
        files
            .compactMap { try? JSONDecoder().decode(CounterFile.self, from: $0).responses }
            .reduce(0) { $0 + max($1, 0) }
    }
}
