import CoreGraphics

/// Where the pet goes when it has no remembered position: the visible sprite itself (not its larger
/// window) sits 40 points from the right and 47 points from the bottom of the usable screen area
/// (the spot Bérenger picked by hand, measured on the real window on 2026-10-18).
public enum DefaultPlacement {
    public static let rightMargin: CGFloat = 40
    public static let bottomMargin: CGFloat = 47

    /// `usableArea`: the screen's visible frame (without the Dock and menu bar).
    /// `spriteInWindow`: the visible sprite inside the window, bottom-left origin.
    /// Returns the window's bottom-left origin.
    public static func origin(
        usableArea: CGRect, spriteInWindow: CGRect, right: CGFloat = rightMargin, bottom: CGFloat = bottomMargin
    ) -> CGPoint {
        CGPoint(x: usableArea.maxX - right - spriteInWindow.maxX, y: usableArea.minY + bottom - spriteInWindow.minY)
    }
}
