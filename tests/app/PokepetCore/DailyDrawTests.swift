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

@Test("sur une année, chaque lignée sort assez souvent")
func overAYearEveryLineageComesOutOftenEnough() {
    // Eleven lineages: about 33 days each on average over 2026.
    let draws = daysOf2026().map { DailyDraw.lineage(for: $0) }
    for lineage in Lineage.allCases {
        #expect((15...65).contains(draws.filter { $0 == lineage }.count), "\(lineage)")
    }
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
