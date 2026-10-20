import Foundation

/// Walks the Claude Code transcripts and feeds the ledger only the lines it has not read yet.
public struct TranscriptScanner: Sendable {
    public let root: URL
    private static let chunkSize = 4 * 1024 * 1024

    public init(root: URL) {
        self.root = root
    }

    public static var standard: TranscriptScanner {
        TranscriptScanner(root: FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude/projects"))
    }

    /// Reads what is new since the last scan. `since`: a file never read and not modified since then
    /// cannot hold a line of the period, so it is marked as read without opening it.
    public func scan(into ledger: inout UsageLedger, since: Date, calendar: Calendar = .current) {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        var seen = Set<String>()
        // Relative paths, joined to `root` as given: the URL enumerator resolves /var into /private/var,
        // which would change the keys of `offsets`.
        let relativePaths = FileManager.default.enumerator(atPath: root.path)?.compactMap { $0 as? String } ?? []
        for url in relativePaths.map({ root.appending(path: $0) }) where url.pathExtension == "jsonl" {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  let size = values.fileSize
            else { continue }
            let path = url.path
            seen.insert(path)
            guard let known = ledger.offsets[path] else {
                if let modified = values.contentModificationDate, modified < since {
                    ledger.offsets[path] = size
                    continue
                }
                ledger.offsets[path] = read(url, from: 0, into: &ledger, calendar: calendar)
                continue
            }
            // A file that shrank was rewritten: read it again; the ledger's ids prevent doubles.
            let start = size < known ? 0 : known
            if size != start { ledger.offsets[path] = read(url, from: start, into: &ledger, calendar: calendar) }
        }
        for path in ledger.offsets.keys where !seen.contains(path) {
            ledger.offsets[path] = nil
        }
    }

    /// Reads from `offset` up to the last complete line; returns the new offset.
    private func read(_ url: URL, from offset: Int, into ledger: inout UsageLedger, calendar: Calendar) -> Int {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return offset }
        defer { try? handle.close() }
        guard (try? handle.seek(toOffset: UInt64(offset))) != nil else { return offset }
        var position = offset
        var pending = Data()
        while let chunk = try? handle.read(upToCount: Self.chunkSize), !chunk.isEmpty {
            pending.append(chunk)
            guard let lastNewline = pending.lastIndex(of: UInt8(ascii: "\n")) else { continue }
            let complete = pending[pending.startIndex...lastNewline]
            for line in complete.split(separator: UInt8(ascii: "\n")) {
                if let entry = TranscriptEntry.parse(Data(line)) { ledger.record(entry, calendar: calendar) }
            }
            position += complete.count
            pending = Data(pending[pending.index(after: lastNewline)...])
        }
        return position
    }
}
