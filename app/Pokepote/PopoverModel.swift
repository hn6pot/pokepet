import AppKit
import Observation
import PokepetCore

/// What the menu bar window shows; refreshed each time it opens.
@MainActor
@Observable
final class PopoverModel {
    enum Tab {
        case recap, settings
    }

    var tab: Tab = .recap
    private(set) var appearance: Appearance?
    /// `nil` until the first reading of the transcripts is over.
    private(set) var recap: Recap?
    @ObservationIgnored private var scanning = false
    /// The « Réglages » tab's values, applied to the companion as soon as they change.
    var companionVisible = true {
        didSet { if companionVisible != loops.companionVisible { loops.companionVisible = companionVisible } }
    }
    var size = 1.0 {
        didSet { if size != loops.size { loops.setSize(size) } }
    }
    /// The large animated Pokémon of the header.
    private(set) var headerImages: [NSImage] = []
    private var headerPlayer = FramePlayer(durations: [1], looping: true)
    private let headerStart = Date()

    @ObservationIgnored let loops: Loops
    @ObservationIgnored private let sprites: SpriteSource

    init(loops: Loops, sprites: SpriteSource) {
        self.loops = loops
        self.sprites = sprites
    }

    func refresh() {
        let next = loops.appearance
        if next?.species != appearance?.species {
            let frames = next.map { SpriteFrames.idle($0.species, sprites: sprites, height: 64) } ?? (images: [], durations: [])
            headerImages = frames.images
            headerPlayer = FramePlayer(durations: frames.durations, looping: true)
        }
        appearance = next
        companionVisible = loops.companionVisible
        size = loops.size
        refreshUsage()
    }

    /// Reads the new transcript lines away from the main thread (the first time, the whole month):
    /// one reading at a time, the window shows « … » until it is over.
    private func refreshUsage() {
        guard !scanning else { return }
        scanning = true
        let responses = loops.dayResponses
        Task {
            let result = await Task.detached(priority: .utility) { Self.readUsage(responses: responses) }.value
            recap = result.recap
            scanning = false
            if let error = result.error { AppDelegate.log("usage.json non enregistré : \(error)") }
        }
    }

    private nonisolated static func readUsage(responses: Int) -> (recap: Recap, error: String?) {
        let url = StateDirectory.standard.root.appending(path: "usage.json")
        var ledger = UsageLedger.load(from: url)
        let now = Date()
        TranscriptScanner.standard.scan(into: &ledger, since: Recap.monthStart(now: now))
        ledger.forgetIDs(before: PokepetDay.key(now.addingTimeInterval(-40 * 86_400)))
        var failure: String?
        do { try ledger.save(to: url) } catch { failure = "\(error)" }
        return (Recap.make(ledger: ledger, responses: responses, now: now), failure)
    }

    func headerImage(at date: Date) -> NSImage? {
        guard !headerImages.isEmpty else { return nil }
        return headerImages[min(headerPlayer.frame(after: date.timeIntervalSince(headerStart)), headerImages.count - 1)]
    }
}
