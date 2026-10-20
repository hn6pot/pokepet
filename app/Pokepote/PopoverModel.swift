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
    }

    func headerImage(at date: Date) -> NSImage? {
        guard !headerImages.isEmpty else { return nil }
        return headerImages[min(headerPlayer.frame(after: date.timeIntervalSince(headerStart)), headerImages.count - 1)]
    }
}
