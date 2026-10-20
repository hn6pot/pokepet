import Foundation
import Testing
@testable import PokepetCore

private let paris: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
    return calendar
}()

/// The start of October 2026 for Poképote: the 1st at 4 a.m., Paris time.
private let since = paris.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 4))!

private func newRoot() -> URL {
    FileManager.default.temporaryDirectory.appending(path: "pokepet-scan-\(UUID())")
}

private func replyLine(_ id: String, output: Int) -> String {
    #"{"type":"assistant","timestamp":"2026-10-20T13:00:00.000Z","entrypoint":"cli","message":{"id":""# + id
        + #"","usage":{"output_tokens":"# + String(output) + "}}}\n"
}

private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

private func append(_ text: String, to url: URL) throws {
    let handle = try FileHandle(forWritingTo: url)
    try handle.seekToEnd()
    try handle.write(contentsOf: Data(text.utf8))
    try handle.close()
}

private func size(of url: URL) -> Int {
    (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? -1
}

@Test("lit tous les .jsonl, sous-dossiers compris, et rien d'autre")
func readsEveryJsonlFileRecursively() throws {
    let root = newRoot()
    try write(replyLine("a", output: 1), to: root.appending(path: "p/s1.jsonl"))
    try write(replyLine("b", output: 2), to: root.appending(path: "p/s1/subagents/agent-x.jsonl"))
    try write(replyLine("c", output: 4), to: root.appending(path: "p/notes.txt"))
    var ledger = UsageLedger()
    TranscriptScanner(root: root).scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 3)
}

@Test("au passage suivant, ne lit que la suite")
func readsOnlyWhatIsNew() throws {
    let root = newRoot()
    let file = root.appending(path: "p/s.jsonl")
    try write(replyLine("a", output: 1), to: file)
    var ledger = UsageLedger()
    let scanner = TranscriptScanner(root: root)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    try append(replyLine("b", output: 10), to: file)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 11)
    #expect(ledger.offsets[file.path] == size(of: file))
}

@Test("une dernière ligne en cours d'écriture est lue une fois complète")
func aPartialLastLineIsReadOnceComplete() throws {
    let root = newRoot()
    let file = root.appending(path: "p/s.jsonl")
    let line = replyLine("a", output: 5)
    try write(String(line.dropLast()), to: file)          // sans le \n final
    var ledger = UsageLedger()
    let scanner = TranscriptScanner(root: root)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 0)
    try append("\n", to: file)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 5)
}

@Test("un fichier qui rétrécit est relu depuis le début, sans doublon")
func aShrunkFileIsReadAgainWithoutDoubles() throws {
    let root = newRoot()
    let file = root.appending(path: "p/s.jsonl")
    try write(replyLine("a", output: 5) + replyLine("b", output: 7) + replyLine("c", output: 9), to: file)
    var ledger = UsageLedger()
    let scanner = TranscriptScanner(root: root)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    try write(replyLine("a", output: 5) + replyLine("d", output: 1), to: file)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 22)
}

@Test("un fichier supprimé garde ses totaux et sort des positions")
func aDeletedFileKeepsItsTotals() throws {
    let root = newRoot()
    let file = root.appending(path: "p/s.jsonl")
    try write(replyLine("a", output: 5), to: file)
    var ledger = UsageLedger()
    let scanner = TranscriptScanner(root: root)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    try FileManager.default.removeItem(at: file)
    scanner.scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 5)
    #expect(ledger.offsets[file.path] == nil)
}

@Test("un fichier jamais lu et pas modifié depuis le début du mois est sauté")
func filesUntouchedSinceTheStartAreSkipped() throws {
    let root = newRoot()
    let file = root.appending(path: "p/old.jsonl")
    try write(replyLine("a", output: 5), to: file)
    try FileManager.default.setAttributes(
        [.modificationDate: paris.date(from: DateComponents(year: 2026, month: 8, day: 1))!], ofItemAtPath: file.path)
    var ledger = UsageLedger()
    TranscriptScanner(root: root).scan(into: &ledger, since: since, calendar: paris)
    #expect(ledger.day("2026-10-20").you.output == 0)
    #expect(ledger.offsets[file.path] == size(of: file))
}
