import AppKit
import PokepetCore

/// Draws the current image, enlarged without smoothing, the « ! » bubble and the white flash.
/// Forwards the mouse to the `MouseGestures`.
final class SpriteView: NSView {
    var image: CGImage? { didSet { if image !== oldValue { needsDisplay = true } } }
    /// Screen points per sprite pixel.
    var scale: CGFloat = 3 { didSet { if scale != oldValue { needsDisplay = true } } }
    var bubble = false { didSet { if bubble != oldValue { needsDisplay = true } } }
    /// Opacity of the white flash, from 0 to 1.
    var flash: CGFloat = 0 { didSet { if flash != oldValue { needsDisplay = true } } }
    /// The height kept above the sprite for the bubble.
    var bubbleHeight: CGFloat { 12 * scale }
    var gestures: MouseGestures?

    /// The rectangle where the sprite is drawn: centred in the area below the bubble.
    var spriteFrame: CGRect {
        guard let image else { return .zero }
        let width = CGFloat(image.width) * scale, height = CGFloat(image.height) * scale
        let area = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - bubbleHeight)
        return CGRect(x: area.midX - width / 2, y: area.midY - height / 2, width: width, height: height)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext, let image else { return }
        context.interpolationQuality = .none
        let frame = spriteFrame
        context.draw(image, in: frame)
        if flash > 0 {
            context.saveGState()
            context.clip(to: frame, mask: image)
            context.setFillColor(NSColor.white.withAlphaComponent(flash).cgColor)
            context.fill(frame)
            context.restoreGState()
        }
        if bubble { drawBubble() }
    }

    /// The circle of the « ! » bubble, set on top of the sprite.
    private var bubbleFrame: CGRect {
        let frame = spriteFrame, radius = 5 * scale
        return CGRect(x: frame.midX - radius, y: frame.maxY, width: radius * 2, height: radius * 2)
    }

    private func drawBubble() {
        let circle = bubbleFrame
        let radius = circle.width / 2
        NSColor.white.setFill()
        NSBezierPath(ovalIn: circle).fill()
        NSColor.black.setStroke()
        let outline = NSBezierPath(ovalIn: circle.insetBy(dx: 1, dy: 1))
        outline.lineWidth = 2
        outline.stroke()
        let text = NSAttributedString(string: "!", attributes: [
            .font: NSFont.boldSystemFont(ofSize: radius * 1.4), .foregroundColor: NSColor.systemRed,
        ])
        let size = text.size()
        text.draw(at: CGPoint(x: circle.midX - size.width / 2, y: circle.midY - size.height / 2))
    }

    /// The visible rectangle of each image already seen (a sheet only has a few images).
    private var visibleFrames: [ObjectIdentifier: CGRect] = [:]

    /// True if the point (view coordinates) falls on the sprite's silhouette (the rectangle of its visible
    /// pixels, plus a 2-pixel margin), or on the bubble.
    func hitsSprite(_ point: CGPoint) -> Bool {
        guard let image else { return false }
        if bubble && HitArea.isInCircle(point, frame: bubbleFrame) { return true }
        let key = ObjectIdentifier(image)
        if visibleFrames[key] == nil { visibleFrames[key] = HitArea.visibleBounds(image) ?? .null }
        guard let visible = visibleFrames[key], !visible.isNull else { return false }
        // Image pixels (origin at the top left) → view points (origin at the bottom left).
        let frame = spriteFrame
        let silhouette = CGRect(
            x: frame.minX + visible.minX * scale, y: frame.maxY - visible.maxY * scale,
            width: visible.width * scale, height: visible.height * scale)
        return silhouette.insetBy(dx: -2 * scale, dy: -2 * scale).contains(point)
    }

    /// The first click acts right away, even if Poképote is not the active app.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) { gestures?.press() }
    override func mouseDragged(with event: NSEvent) { gestures?.drag() }
    override func mouseUp(with event: NSEvent) { gestures?.release() }
    override func scrollWheel(with event: NSEvent) { gestures?.scroll(event.scrollingDeltaY) }
    override func rightMouseDown(with event: NSEvent) { gestures?.rightClick(event) }
}
