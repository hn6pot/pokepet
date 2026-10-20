import AppKit
import PokepetCore

/// The Pokémon of the day in the menu bar, animated; a click opens or closes the window.
@MainActor
final class MenuBarIcon: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let sprites: SpriteSource
    private let loops: Loops
    private let popover: RecapPopover
    private var species: Species?
    private var images: [NSImage] = []
    private var player = FramePlayer(durations: [1], looping: true)
    private var start = Date()
    private var shown = -1
    private var timer: Timer?

    init(sprites: SpriteSource, loops: Loops, popover: RecapPopover) {
        self.sprites = sprites
        self.loops = loops
        self.popover = popover
        super.init()
        item.button?.target = self
        item.button?.action = #selector(clicked)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        tick()
    }

    /// Follows the companion's Pokémon; the button is touched only when the image to show changes.
    private func tick() {
        guard let button = item.button, let current = loops.appearance?.species else { return }
        if current != species {
            species = current
            let frames = SpriteFrames.idle(current, sprites: sprites, height: 18)
            images = frames.images
            player = FramePlayer(durations: frames.durations, looping: true)
            start = Date()
            shown = -1
        }
        guard !images.isEmpty else { return }
        let index = min(player.frame(after: Date().timeIntervalSince(start)), images.count - 1)
        if index != shown {
            shown = index
            button.image = images[index]        }
    }

    @objc private func clicked() {
        guard let button = item.button else { return }
        popover.toggle(relativeTo: button)
    }
}
