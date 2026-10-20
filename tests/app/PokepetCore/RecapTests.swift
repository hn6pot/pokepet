import Foundation
import Testing
@testable import PokepetCore

private let paris: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
    return calendar
}()

private func at(_ iso: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.date(from: iso)!
}

private func message(_ uuid: String, _ iso: String, _ origin: Origin = .you) -> TranscriptEntry {
    .typedMessage(uuid: uuid, date: at(iso), origin: origin)
}

private func reply(_ id: String, _ iso: String, output: Int, cacheRead: Int = 0, _ origin: Origin = .you) -> TranscriptEntry {
    .reply(messageID: id, date: at(iso), origin: origin, output: output, cacheRead: cacheRead)
}

@Test("aujourd'hui suit la bascule à 4 h, et le mois aussi")
func todayFollowsThe4amRollover() {
    var ledger = UsageLedger()
    ledger.record(reply("a", "2026-10-31T20:00:00.000Z", output: 100), calendar: paris)
    let recap = Recap.make(ledger: ledger, responses: 14, now: at("2026-11-01T02:30:00.000Z"), calendar: paris)   // 3 h 30 le 1er novembre
    #expect(recap.output == 100)
    #expect(recap.monthName == "Octobre")
    #expect(recap.responses == 14)
}

@Test("le mois compte tes messages et met les automatiques à part")
func monthKeepsAutomaticApart() {
    var ledger = UsageLedger()
    ledger.record(message("u1", "2026-10-02T10:00:00.000Z"), calendar: paris)
    ledger.record(message("u2", "2026-10-20T10:00:00.000Z"), calendar: paris)
    ledger.record(message("u3", "2026-10-20T10:00:00.000Z", .automatic), calendar: paris)
    let recap = Recap.make(ledger: ledger, responses: 0, now: at("2026-10-20T12:00:00.000Z"), calendar: paris)
    #expect(recap.messages == 2)
    #expect(recap.automaticMessages == 1)
}

@Test("les tokens ne comptent que tes conversations")
func tokensCountOnlyYourConversations() {
    var ledger = UsageLedger()
    ledger.record(reply("a", "2026-10-20T10:00:00.000Z", output: 100, cacheRead: 1_000), calendar: paris)
    ledger.record(reply("b", "2026-10-20T10:00:00.000Z", output: 50, cacheRead: 500, .automatic), calendar: paris)
    let recap = Recap.make(ledger: ledger, responses: 0, now: at("2026-10-20T12:00:00.000Z"), calendar: paris)
    #expect(recap.output == 100)
    #expect(recap.cacheRead == 1_000)
}

@Test("le début du mois Poképote est le 1er à 4 h")
func monthStartIsTheFirstAt4() {
    #expect(Recap.monthStart(now: at("2026-11-01T02:30:00.000Z"), calendar: paris) == at("2026-10-01T02:00:00.000Z"))
    #expect(Recap.monthStart(now: at("2026-10-20T12:00:00.000Z"), calendar: paris) == at("2026-10-01T02:00:00.000Z"))
}
