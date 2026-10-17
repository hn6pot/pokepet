import AppKit

/// Turns the mouse into actions: dragging moves, the wheel changes the size,
/// a click opens the waiting conversation (or makes the companion hop), a right click opens the menu.
@MainActor
final class MouseGestures {
    private let window: NSWindow
    private unowned let view: SpriteView
    private unowned let loops: Loops
    private var start = CGPoint.zero
    private var origin = CGPoint.zero
    private var hasDragged = false

    init(window: NSWindow, view: SpriteView, loops: Loops) {
        self.window = window
        self.view = view
        self.loops = loops
    }

    func press() {
        start = NSEvent.mouseLocation
        origin = window.frame.origin
        hasDragged = false
        loops.dragging = true
    }

    func drag() {
        let mouse = NSEvent.mouseLocation
        let dx = mouse.x - start.x, dy = mouse.y - start.y
        // Less than 3 points: it is still a shaky click.
        if hypot(dx, dy) > 3 { hasDragged = true }
        if hasDragged { window.setFrameOrigin(CGPoint(x: origin.x + dx, y: origin.y + dy)) }
    }

    func release() {
        loops.dragging = false
        if hasDragged {
            loops.positionChosen()
        } else {
            loops.click()
        }
    }

    func scroll(_ delta: CGFloat) {
        guard delta != 0 else { return }
        loops.changeSize(factor: 1 + Double(delta) * 0.01)
    }

    func rightClick(_ event: NSEvent) {
        guard let appearance = loops.appearance else { return }
        let menu = ContextMenu.build(
            appearance: appearance,
            anotherPokemon: { [weak loops] in loops?.anotherPokemon() },
            normalSize: { [weak loops] in loops?.normalSize() })
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
}
