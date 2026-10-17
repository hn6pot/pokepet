/// Draws the lineage of the day among the ten, from the date: same date, same baby, nothing stored.
/// Swift's `hashValue` changes at every launch: we compute our own hash (FNV-1a),
/// then mix it (MurmurHash3's fmix32), otherwise the days would alternate fire, electric, fire…
public enum DailyDraw {
    public static func lineage(for key: String) -> Lineage {
        Lineage.allCases[Int(mix(fnv1a(key)) % UInt32(Lineage.allCases.count))]
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
public struct DailyChoice: Equatable, Sendable {
    public let day: String
    public let lineage: Lineage

    public init(day: String, lineage: Lineage) {
        self.day = day
        self.lineage = lineage
    }
}
