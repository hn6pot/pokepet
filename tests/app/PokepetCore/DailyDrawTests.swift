import Foundation
import Testing
@testable import PokepetCore

private func daysOf2026() -> [String] {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    let start = c.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
    return (0..<365).map { PokepetDay.key(c.date(byAdding: .day, value: $0, to: start)!, calendar: c) }
}

@Test("même date, même lignée")
func sameDateSameLineage() {
    #expect(DailyDraw.lineage(for: "2026-10-15") == DailyDraw.lineage(for: "2026-10-15"))
}

@Test("l'empreinte est stable")
func hashIsStable() {
    // FNV-1a 32-bit reference value: if it changes, the past babies change too.
    #expect(DailyDraw.fnv1a("a") == 0xE40C_292C)
}

@Test("le numéro du jour compte depuis le 1er janvier 1970")
func dayNumberCountsFrom1970() {
    #expect(DailyDraw.dayNumber("1970-01-01") == 0)
    #expect(DailyDraw.dayNumber("2000-03-01") == 11_017)
    #expect(DailyDraw.dayNumber("2026-11-12") == 20_769)
}

@Test("sur onze jours alignés, chaque lignée sort exactement une fois")
func overElevenAlignedDaysEveryLineageComesOutExactlyOnce() {
    let count = Lineage.allCases.count
    let blocks = Dictionary(grouping: daysOf2026()) { DailyDraw.dayNumber($0) / count }
    #expect(blocks.count > 30)
    for (block, keys) in blocks where keys.count == count {
        #expect(Set(keys.map { DailyDraw.lineage(for: $0) }).count == count, "\(block)")
    }
}

@Test("sur une année, chaque lignée sort autant que les autres")
func overAYearEveryLineageComesOutAsOftenAsTheOthers() {
    // Eleven lineages, 365 days: 33 full periods, plus a partial one at each end of the year.
    let draws = daysOf2026().map { DailyDraw.lineage(for: $0) }
    for lineage in Lineage.allCases {
        #expect((32...35).contains(draws.filter { $0 == lineage }.count), "\(lineage)")
    }
}

@Test("l'ordre change d'une période de onze jours à l'autre")
func theOrderChangesFromOnePeriodToTheNext() {
    let orders = (0..<20).map { DailyDraw.order(block: $0) }
    #expect(Set(orders).count == 20)
}

@Test("le bébé change souvent d'un jour à l'autre")
func theBabyOftenChangesFromOneDayToTheNext() {
    let draws = daysOf2026().map { DailyDraw.lineage(for: $0) }
    let repeats = zip(draws, draws.dropFirst()).filter { $0 == $1 }.count
    #expect(repeats < 80)
}

@Test("une autre lignée n'est jamais la même et peut être n'importe laquelle")
func anotherLineageIsNeverTheSameAndCanBeAnyOther() {
    var generator = FixedRandom(state: 11)
    for lineage in Lineage.allCases {
        let others = (0..<200).map { _ in DailyDraw.other(than: lineage, using: &generator) }
        #expect(!others.contains(lineage))
        #expect(Set(others).count == Lineage.allCases.count - 1)
    }
}
