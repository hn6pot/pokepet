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

@Test("un message compte pour sa journée Poképote (bascule à 4 h)")
func messageCountsOnItsPokepetDay() {
    var ledger = UsageLedger()
    ledger.record(message("u1", "2026-10-20T01:30:00.000Z"), calendar: paris)   // 3 h 30 à Paris
    #expect(ledger.day("2026-10-19").you.messages == 1)
    #expect(ledger.day("2026-10-20").you.messages == 0)
}

@Test("une réponse écrite sur plusieurs lignes compte une fois")
func replyCountsOnce() {
    var ledger = UsageLedger()
    for _ in 0..<3 { ledger.record(reply("msg_1", "2026-10-20T13:00:00.000Z", output: 511, cacheRead: 9000), calendar: paris) }
    #expect(ledger.day("2026-10-20").you == UsageTotals(messages: 0, output: 511, cacheRead: 9000))
}

@Test("une ligne suivante avec plus de tokens relève le compte, jamais ne le baisse")
func aLaterLineWithMoreTokensRaisesTheCount() {
    var ledger = UsageLedger()
    ledger.record(reply("msg_1", "2026-10-20T13:00:00.000Z", output: 3), calendar: paris)
    ledger.record(reply("msg_1", "2026-10-20T13:00:01.000Z", output: 511), calendar: paris)
    ledger.record(reply("msg_1", "2026-10-20T13:00:02.000Z", output: 200), calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 511)
}

@Test("un message recopié dans un autre fichier compte une fois")
func aMessageCopiedIntoAnotherFileCountsOnce() {
    var ledger = UsageLedger()
    ledger.record(message("u1", "2026-10-20T13:00:00.000Z"), calendar: paris)
    ledger.record(message("u1", "2026-10-20T13:00:00.000Z"), calendar: paris)
    #expect(ledger.day("2026-10-20").you.messages == 1)
}

@Test("toi et les automatiques sont comptés à part")
func youAndAutomaticAreSeparate() {
    var ledger = UsageLedger()
    ledger.record(message("u1", "2026-10-20T13:00:00.000Z"), calendar: paris)
    ledger.record(message("u2", "2026-10-20T13:00:00.000Z", .automatic), calendar: paris)
    ledger.record(reply("msg_9", "2026-10-20T13:00:00.000Z", output: 40, .automatic), calendar: paris)
    #expect(ledger.day("2026-10-20").you == UsageTotals(messages: 1, output: 0, cacheRead: 0))
    #expect(ledger.day("2026-10-20").automatic == UsageTotals(messages: 1, output: 40, cacheRead: 0))
}

@Test("le mois additionne ses jours, et seulement les siens")
func monthAddsUpItsDays() {
    var ledger = UsageLedger()
    ledger.record(message("a", "2026-09-30T12:00:00.000Z"), calendar: paris)
    ledger.record(message("b", "2026-10-01T12:00:00.000Z"), calendar: paris)
    ledger.record(message("c", "2026-10-20T12:00:00.000Z"), calendar: paris)
    #expect(ledger.month("2026-10").you.messages == 2)
}

@Test("oublier les vieux identifiants garde les totaux")
func forgetIDsKeepsTotals() {
    var ledger = UsageLedger()
    ledger.record(reply("old", "2026-08-01T12:00:00.000Z", output: 10), calendar: paris)
    ledger.record(reply("new", "2026-10-20T12:00:00.000Z", output: 20), calendar: paris)
    ledger.forgetIDs(before: "2026-09-15")
    #expect(ledger.day("2026-08-01").you.output == 10)
    #expect(Set(ledger.replies.keys) == ["new"])
}

@Test("le registre s'enregistre et se relit à l'identique")
func saveAndLoadRoundTrip() throws {
    var ledger = UsageLedger()
    ledger.record(reply("msg_1", "2026-10-20T13:00:00.000Z", output: 511), calendar: paris)
    ledger.offsets["/tmp/x.jsonl"] = 1234
    let url = FileManager.default.temporaryDirectory.appending(path: "pokepet-\(UUID())/usage.json")
    try ledger.save(to: url)
    #expect(UsageLedger.load(from: url) == ledger)
}

@Test("un registre absent ou abîmé repart de zéro")
func anUnreadableLedgerStartsEmpty() throws {
    let dir = FileManager.default.temporaryDirectory.appending(path: "pokepet-\(UUID())")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appending(path: "usage.json")
    #expect(UsageLedger.load(from: url) == UsageLedger())
    try Data("{\"days\":".utf8).write(to: url)
    #expect(UsageLedger.load(from: url) == UsageLedger())
}
