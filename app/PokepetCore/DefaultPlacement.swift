import CoreGraphics

/// Where the pet goes when it has no remembered position: the visible sprite itself (not its larger
/// window) sits `margin` points (12) from the bottom-right corner of the usable screen area.
public enum DefaultPlacement {
    public static let margin: CGFloat = 12

    /// `usableArea`: the screen's visible frame (without the Dock and menu bar).
    /// `spriteInWindow`: the visible sprite inside the window, bottom-left origin.
    /// Returns the window's bottom-left origin.
    public static func origin(usableArea: CGRect, spriteInWindow: CGRect, margin: CGFloat = margin) -> CGPoint {
        CGPoint(x: usableArea.maxX - margin - spriteInWindow.maxX, y: usableArea.minY + margin - spriteInWindow.minY)
    }
}
