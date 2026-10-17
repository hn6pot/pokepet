import Foundation
import Testing
@testable import PokepetCore

private let paris: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Paris")!
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
    paris.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Test("avant 4 h, on est encore la veille")
func before4amIsStillThePreviousDay() {
    #expect(PokepetDay.key(date(2026, 10, 16, 3, 59), calendar: paris) == "2026-10-15")
}

@Test("à 4 h, la journée bascule")
func dayRollsOverAt4am() {
    #expect(PokepetDay.key(date(2026, 10, 16, 4, 0), calendar: paris) == "2026-10-16")
}

@Test("le soir, c'est le jour même")
func eveningIsTheSameDay() {
    #expect(PokepetDay.key(date(2026, 10, 15, 23, 30), calendar: paris) == "2026-10-15")
}

@Test("le passage à l'heure d'été ne décale pas la bascule")
func switchToSummerTimeDoesNotShiftTheRollover() {
    // On 29 March 2026, in Paris, 2 a.m. becomes 3 a.m.
    #expect(PokepetDay.key(date(2026, 3, 29, 3, 59), calendar: paris) == "2026-03-28")
    #expect(PokepetDay.key(date(2026, 3, 29, 4, 30), calendar: paris) == "2026-03-29")
}

@Test("le retour à l'heure d'hiver ne décale pas la bascule")
func switchBackToWinterTimeDoesNotShiftTheRollover() {
    // On 25 October 2026, in Paris, 3 a.m. becomes 2 a.m. again.
    #expect(PokepetDay.key(date(2026, 10, 25, 3, 30), calendar: paris) == "2026-10-24")
    #expect(PokepetDay.key(date(2026, 10, 25, 4, 0), calendar: paris) == "2026-10-25")
}

@Test("le nouvel an bascule à 4 h")
func newYearRollsOverAt4am() {
    #expect(PokepetDay.key(date(2027, 1, 1, 2, 0), calendar: paris) == "2026-12-31")
}
