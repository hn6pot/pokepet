import AppKit
import PokepetCore

/// The images of a Pokémon's `Idle` animation, facing front, ready for the menu bar or the window:
/// cut to the visible pixels of all its frames (so it does not wobble), enlarged without smoothing.
@MainActor
enum SpriteFrames {
    static func idle(_ species: Species, sprites: SpriteSource, height: CGFloat) -> (images: [NSImage], durations: [Int]) {
        guard let animation = sprites.animation(.idle, species: species, direction: .front),
              let first = animation.images.first
        else { return ([], []) }
        let visible = animation.images.compactMap(HitArea.visibleBounds).reduce(CGRect.null) { $0.union($1) }
        let crop = visible.isNull ? CGRect(x: 0, y: 0, width: first.width, height: first.height) : visible
        let size = NSSize(width: (crop.width * height / crop.height).rounded(), height: height)
        let images = animation.images.map { image in
            let piece = image.cropping(to: crop) ?? image
            return NSImage(size: size, flipped: false) { rect in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.interpolationQuality = .none
                context.draw(piece, in: rect)
                return true
            }
        }
        return (images, animation.durations)
    }
}
