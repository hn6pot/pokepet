/// Draws the lineage of the day without replacement, from the date: same date, same baby, nothing stored.
/// The days are cut into periods of as many days as there are lineages; each period shuffles the lineages
/// in its own order, so every lineage comes out exactly once per period.
/// Swift's `hashValue` changes at every launch: we compute our own hash (FNV-1a),
/// then mix it (MurmurHash3's fmix32), otherwise the periods would alternate fire, electric, fire…
public enum DailyDraw {
    public static func lineage(for key: String) -> Lineage {
        let count = Lineage.allCases.count
        let (block, position) = dayNumber(key).quotientAndRemainder(dividingBy: count)
        return order(block: block)[position]
    }

    /// The lineages in the order of one period: a Fisher-Yates shuffle seeded by the period's hash.
    static func order(block: Int) -> [Lineage] {
        var lineages = Lineage.allCases
        var state = mix(fnv1a("period-\(block)"))
        for last in stride(from: lineages.count - 1, to: 0, by: -1) {
            state = mix(state &+ 0x9E37_79B9)
            lineages.swapAt(last, Int(state % UInt32(last + 1)))
        }
        return lineages
    }

    /// Days since 1970-01-01 of a "YYYY-MM-DD" key (proleptic Gregorian, days-from-civil).
    static func dayNumber(_ key: String) -> Int {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Int(fnv1a(key)) }
        let (y, m, d) = (parts[0] - (parts[1] <= 2 ? 1 : 0), parts[1], parts[2])
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let dayOfYear = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    /// Another lineage than `lineage`, at random: for « Un autre Pokémon ».
    public static func other(than lineage: Lineage, using generator: inout some RandomNumberGenerator) -> Lineage {
        Lineage.allCases.filter { $0 != lineage }.randomElement(using: &generator)!
    }

    static func fnv1a(_ text: String) -> UInt32 {
        var h: UInt32 = 2_166_136_261
        for byte in text.utf8 {
            h ^= UInt32(byte)
            h = h &* 16_777_619
        }
        return h
    }

    static func mix(_ value: UInt32) -> UInt32 {
        var h = value
        h ^= h >> 16
        h = h &* 0x85EB_CA6B
        h ^= h >> 13
        h = h &* 0xC2B2_AE35
        h ^= h >> 16
        return h
    }
}

/// The lineage picked with « Un autre Pokémon » for a day; it only holds for that day.
/// The new Pokémon starts from zero: it evolves on the answers counted since the choice.
public struct DailyChoice: Equatable, Sendable {
    public let day: String
    public let lineage: Lineage
    /// The day's answer count when the choice was made.
    public let startResponses: Int

    public init(day: String, lineage: Lineage, startResponses: Int = 0) {
        self.day = day
        self.lineage = lineage
        self.startResponses = startResponses
    }
}
