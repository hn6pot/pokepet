import Foundation
import Testing
@testable import PokepetCore

/// A fake `~/.pokepet/` in a temporary directory, deleted at the end of the test.
private final class FakeDirectory {
    let root = FileManager.default.temporaryDirectory.appending(path: "pokepet-\(UUID().uuidString)")

    func write(_ path: String, _ text: String) throws {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }

    func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: root.appending(path: path).path)
    }

    deinit { try? FileManager.default.removeItem(at: root) }
}

private let now = Date(timeIntervalSince1970: 1_792_072_931)

@Test("garder, ignorer et supprimer")
func keepIgnoreAndDelete() throws {
    let d = FakeDirectory()
    try d.write("sessions/a.json", #"{"etat":"travaille","majLe":"2026-10-15T14:00:00Z","pid":10}"#)
    try d.write("sessions/b.json", #"{"etat":"fermee","majLe":"2026-10-15T14:00:00Z","pid":10}"#)
    try d.write("sessions/c.json", #"{"etat":"attend","majLe":"2026-10-15T14:00:00Z","pid":99}"#)
    try d.write("sessions/d.json", "{")
    try d.write("sessions/notes.txt", "pas du JSON")

    let kept = StateDirectory(root: d.root).sessions(now: now) { $0 == 10 }

    #expect(kept.map(\.status) == [.working])
    #expect(!d.exists("sessions/b.json"))
    #expect(!d.exists("sessions/c.json"))
    #expect(d.exists("sessions/d.json"))
    #expect(d.exists("sessions/notes.txt"))
}

@Test("sans dossier, rien ne casse")
func nothingBreaksWithoutDirectory() {
    let directory = StateDirectory(root: URL(filePath: "/nexiste/pas"))
    #expect(directory.sessions(now: now).isEmpty)
    #expect(directory.counters(day: "2026-10-15").isEmpty)
}

@Test("les compteurs sont ceux du jour demandé")
func countersAreThoseOfTheRequestedDay() throws {
    let d = FakeDirectory()
    try d.write("jour/2026-10-15/a.json", #"{"reponses":5}"#)
    try d.write("jour/2026-10-15/b.json", #"{"reponses":4}"#)
    try d.write("jour/2026-10-14/a.json", #"{"reponses":30}"#)
    #expect(DailyCounter.total(StateDirectory(root: d.root).counters(day: "2026-10-15")) == 9)
}

@Test("mon propre processus est vivant")
func myOwnProcessIsAlive() {
    #expect(StateDirectory.isPidAlive(ProcessInfo.processInfo.processIdentifier))
}

@Test("un processus terminé est mort")
func aFinishedProcessIsDead() throws {
    let p = Process()
    p.executableURL = URL(filePath: "/usr/bin/true")
    try p.run()
    p.waitUntilExit()
    #expect(!StateDirectory.isPidAlive(p.processIdentifier))
}

@Test("un pid nul ou négatif est mort")
func aZeroOrNegativePidIsDead() {
    #expect(!StateDirectory.isPidAlive(0))
    #expect(!StateDirectory.isPidAlive(-1))
}
